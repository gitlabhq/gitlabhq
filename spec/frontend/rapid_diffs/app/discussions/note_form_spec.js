import { merge } from 'lodash-es';
import { createTestingPinia } from '@pinia/testing';
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { ARROW_UP_KEY, ENTER_KEY, ESC_KEY } from '~/lib/utils/keys';
import { stubComponent } from 'helpers/stub_component';
import { createAlert } from '~/alert';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { COMMENT_FORM } from '~/notes/i18n';
import { clearDraft } from '~/lib/utils/autosave';

jest.mock('~/vue_shared/components/markdown/tracking');
jest.mock('~/lib/utils/autosave');
jest.mock('~/alert');

describe('NoteForm', () => {
  let pinia;
  let wrapper;
  let defaultProps;

  const defaultProvisions = {
    endpoints: {
      previewMarkdown: '/preview',
      markdownDocs: '/docs',
    },
    noteableType: 'Commit',
  };

  const createComponent = (props = {}, provide = {}, stubs = {}) => {
    wrapper = shallowMountExtended(NoteForm, {
      pinia,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: merge(defaultProvisions, provide),
      stubs: { GlSprintf, GlLink, ...stubs },
    });
  };

  const findEditor = () => wrapper.findComponent(MarkdownEditor);
  const findSaveButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((buttonWrapper) => buttonWrapper.text() === 'Save comment')
      .at(0);
  const findCancelButton = () => wrapper.findByTestId('cancel');

  beforeEach(() => {
    defaultProps = {
      saveNote: jest.fn().mockResolvedValue(),
    };
    pinia = createTestingPinia();
    window.gl = {
      GfmAutoComplete: {
        dataSources: {},
      },
    };
  });

  it('shows editor', () => {
    const autosaveKey = 'autosave';
    const supportsQuickActions = true;
    const autofocus = true;
    const restoreFromAutosave = true;
    createComponent({ autosaveKey, supportsQuickActions, autofocus, restoreFromAutosave });
    const editor = findEditor();
    expect(editor.exists()).toBe(true);
    expect(editor.props()).toMatchObject({
      value: '',
      renderMarkdownPath: defaultProvisions.endpoints.previewMarkdown,
      markdownDocsPath: defaultProvisions.endpoints.markdownDocs,
      noteableType: defaultProvisions.noteableType,
      formFieldProps: {
        id: 'note_note',
        name: 'note[note]',
        'aria-label': 'Reply to comment',
        placeholder: 'Write a comment or drag your files here…',
        class: expect.any(String),
        'data-testid': 'reply-field',
      },
      autosaveKey,
      autocompleteDataSources: window.gl.GfmAutoComplete.dataSources,
      disabled: false,
      supportsQuickActions,
      autofocus,
      restoreFromAutosave,
    });
  });

  describe('renderMarkdownPath', () => {
    it('uses base previewMarkdown endpoint when no previewParams', () => {
      createComponent();
      expect(findEditor().props('renderMarkdownPath')).toBe(
        defaultProvisions.endpoints.previewMarkdown,
      );
    });

    it('merges previewParams into the markdown path', () => {
      const previewParams = {
        preview_suggestions: true,
        line: 5,
        file_path: 'app/models/user.rb',
      };
      createComponent({ codeSuggestionsConfig: { previewParams } });
      const path = findEditor().props('renderMarkdownPath');
      expect(path).toContain('preview_suggestions=true');
      expect(path).toContain('line=5');
      expect(path).toContain('file_path=app%2Fmodels%2Fuser.rb');
    });
  });

  describe('editor', () => {
    it.each`
      shiftKey | ctrlKey  | metaKey
      ${true}  | ${false} | ${true}
      ${true}  | ${true}  | ${false}
      ${false} | ${false} | ${true}
      ${false} | ${true}  | ${false}
    `(`submits form on enter keydown`, async ({ shiftKey, metaKey, ctrlKey }) => {
      createComponent(undefined, undefined, {
        MarkdownEditor: stubComponent(MarkdownEditor, {
          template: '<div></div>',
          computed: {
            isContentEditorActive() {
              return true;
            },
          },
        }),
      });
      findEditor().vm.$emit('input', 'edit');
      findEditor().vm.$emit(
        'keydown',
        new KeyboardEvent('keydown', { key: ENTER_KEY, shiftKey, metaKey, ctrlKey }),
      );
      await nextTick();
      expect(defaultProps.saveNote).toHaveBeenCalledWith('edit', shiftKey);
      expect(trackSavedUsingEditor).toHaveBeenCalledWith(
        true,
        `${defaultProvisions.noteableType}_note`,
      );
      expect(findEditor().props('value')).toBe('');
    });

    it('cancels form on escape keydown', () => {
      createComponent();
      findEditor().vm.$emit('keydown', new KeyboardEvent('keydown', { key: ESC_KEY }));
      expect(wrapper.emitted('cancel')).toStrictEqual([[false]]);
    });

    it('propagates handleSuggestDismissed event', () => {
      createComponent();
      findEditor().vm.$emit('handleSuggestDismissed');
      expect(wrapper.emitted('handleSuggestDismissed')).toStrictEqual([[]]);
    });

    it('propagates input event', () => {
      const inputValue = 'foo';
      createComponent();
      findEditor().vm.$emit('input', inputValue);
      expect(wrapper.emitted('input')).toStrictEqual([[inputValue]]);
    });

    describe('last note edit', () => {
      it('calls for last note edit', () => {
        const requestLastNoteEditing = jest.fn().mockReturnValue(true);
        createComponent({ requestLastNoteEditing });
        findEditor().vm.$emit('keydown', new KeyboardEvent('keydown', { key: ARROW_UP_KEY }));
        expect(requestLastNoteEditing).toHaveBeenCalled();
        expect(wrapper.emitted('cancel')).toStrictEqual([[false]]);
      });

      it('does not call for last note edit when has edits', () => {
        const discussion = {};
        const requestLastNoteEditing = jest.fn().mockReturnValue(true);
        createComponent({ discussion, requestLastNoteEditing });
        findEditor().vm.$emit('input', 'edit');
        findEditor().vm.$emit('keydown', new KeyboardEvent('keydown', { key: ARROW_UP_KEY }));
        expect(requestLastNoteEditing).not.toHaveBeenCalled();
        expect(wrapper.emitted('cancel')).toBe(undefined);
      });
    });

    it('appends text', () => {
      const append = jest.fn();
      createComponent(undefined, undefined, {
        MarkdownEditor: { methods: { append }, template: '<div></div>' },
      });
      wrapper.vm.append('some text');
      expect(append).toHaveBeenCalledWith('some text');
    });
  });

  describe('controls', () => {
    it('shows controls', () => {
      createComponent();
      expect(findSaveButton().exists()).toBe(true);
      expect(findCancelButton().exists()).toBe(true);
    });

    it('disables submit when message is empty', () => {
      createComponent();
      expect(findSaveButton().props('disabled')).toBe(true);
    });

    it('enables submit when message is not empty', () => {
      createComponent({ noteBody: 'foo' });
      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('disables submit when submitting the form', async () => {
      createComponent({ noteBody: 'foo' });
      findSaveButton().vm.$emit('click');
      await nextTick();
      expect(findSaveButton().props('disabled')).toBe(true);
    });

    it('cancels form without confirmation', () => {
      createComponent({ autosaveKey: 'key' });
      findCancelButton().vm.$emit('click');
      expect(clearDraft).toHaveBeenCalledWith('key');
      expect(wrapper.emitted('cancel')).toStrictEqual([[false]]);
    });

    it('cancels form with confirmation when text is edited', () => {
      createComponent();
      findEditor().vm.$emit('input', 'edit');
      findCancelButton().vm.$emit('click');
      expect(wrapper.emitted('cancel')).toStrictEqual([[true]]);
    });

    it('skips form cancel when at-who is active', () => {
      createComponent(undefined, undefined, {
        MarkdownEditor: {
          template: '<textarea class="at-who-active"></textarea>',
        },
      });
      findCancelButton().vm.$emit('click');
      expect(wrapper.emitted('cancel')).toBe(undefined);
    });

    it('hides cancel button when canCancel is false', () => {
      createComponent({ canCancel: false });
      expect(findCancelButton().exists()).toBe(false);
    });
  });

  describe('conflicts', () => {
    it('shows conflict message with a link to note', async () => {
      const noteId = 'foo';
      createComponent({ noteId });
      await findEditor().vm.$emit('input', 'changed in child');
      await wrapper.setProps({ noteBody: 'changed in parent' });
      await nextTick();
      expect(wrapper.text()).toContain(
        'This comment changed after you started editing it. Review the updated comment to ensure information is not lost.',
      );
      expect(wrapper.find(`a[href="#note_${noteId}"]`).text()).toBe('updated comment');
    });

    it('shows conflict message without a link to note', async () => {
      createComponent();
      await findEditor().vm.$emit('input', 'changed in child');
      await wrapper.setProps({ noteBody: 'changed in parent' });
      await nextTick();
      expect(wrapper.html()).toContain(
        'This comment changed after you started editing it. Review the updated comment to ensure information is not lost.',
      );
    });
  });

  describe('error handling', () => {
    it('shows alert with error messages on save failure', async () => {
      const saveNote = jest.fn().mockRejectedValue({
        response: {
          status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
          data: { errors: 'Validation failed' },
        },
      });
      createComponent({ saveNote, noteBody: 'test' });

      await findSaveButton().vm.$emit('click');
      await nextTick();
      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({
        message: ['Comment could not be submitted: validation failed.'],
        parent: wrapper.element,
        error: expect.any(Object),
      });
    });

    it('uses custom error messages when provided', async () => {
      const saveNote = jest.fn().mockRejectedValue({
        response: {
          status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
          data: { errors: 'Custom error' },
        },
      });
      const saveNoteErrorMessages = {
        error: 'Update failed: %{reason}',
        defaultError: 'Update error',
      };
      createComponent({ saveNote, noteBody: 'test', saveNoteErrorMessages });

      await findSaveButton().vm.$emit('click');
      await nextTick();
      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({
        message: ['Update failed: custom error'],
        parent: wrapper.element,
        error: expect.any(Object),
      });
    });

    it('shows quick actions error messages', async () => {
      const saveNote = jest.fn().mockRejectedValue({
        response: {
          status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
          data: {
            quick_actions_status: {
              error_messages: ['Quick action error 1', 'Quick action error 2'],
            },
          },
        },
      });
      createComponent({ saveNote, noteBody: 'test' });

      await findSaveButton().vm.$emit('click');
      await nextTick();
      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({
        message: ['Quick action error 1', 'Quick action error 2'],
        parent: wrapper.element,
        error: expect.any(Object),
      });
    });

    it('shows default error when no specific error message', async () => {
      const saveNote = jest.fn().mockRejectedValue({ response: null });
      createComponent({ saveNote, noteBody: 'test' });

      await findSaveButton().vm.$emit('click');
      await nextTick();
      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({
        message: [COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK],
        parent: wrapper.element,
        error: expect.any(Object),
      });
    });
  });

  describe('draft review support', () => {
    const saveDraft = jest.fn().mockResolvedValue();

    const findAddToReviewButton = () => wrapper.findByTestId('add-to-review-button');
    const findCommentButton = () => wrapper.findByTestId('reply-comment-button');

    describe('when saveDraft is not provided', () => {
      it('does not show add-to-review button', () => {
        createComponent({ noteBody: 'test' });
        expect(findAddToReviewButton().exists()).toBe(false);
      });

      it('shows comment button as primary with saveButtonTitle', () => {
        createComponent({ noteBody: 'test', saveButtonTitle: 'Comment' });
        expect(findCommentButton().text()).toBe('Comment');
        expect(findCommentButton().props('category')).toBe('primary');
      });
    });

    describe('when saveDraft is provided', () => {
      it('shows add-to-review button', () => {
        createComponent({ saveDraft, noteBody: 'test' });
        expect(findAddToReviewButton().exists()).toBe(true);
      });

      it('shows "Start a review" when hasDrafts is false', () => {
        createComponent({ saveDraft, noteBody: 'test', hasDrafts: false });
        expect(findAddToReviewButton().text()).toBe('Start a review');
      });

      it('shows "Add to review" when hasDrafts is true', () => {
        createComponent({ saveDraft, noteBody: 'test', hasDrafts: true });
        expect(findAddToReviewButton().text()).toBe('Add to review');
      });

      it('shows comment button as secondary with "Add comment now"', () => {
        createComponent({ saveDraft, noteBody: 'test' });
        expect(findCommentButton().text()).toBe('Add comment now');
        expect(findCommentButton().props('category')).toBe('secondary');
      });

      it('disables add-to-review button when text is empty', () => {
        createComponent({ saveDraft });
        expect(findAddToReviewButton().props('disabled')).toBe(true);
      });

      it('calls saveDraft on add-to-review button click', async () => {
        createComponent({ saveDraft, noteBody: 'draft text' }, undefined, {
          MarkdownEditor: stubComponent(MarkdownEditor, {
            template: '<div></div>',
            computed: {
              isContentEditorActive() {
                return false;
              },
            },
          }),
        });
        await findAddToReviewButton().vm.$emit('click');
        await nextTick();
        expect(saveDraft).toHaveBeenCalledWith('draft text');
      });

      it('calls saveDraft on shift+cmd+enter', async () => {
        createComponent({ saveDraft, noteBody: 'draft text' }, undefined, {
          MarkdownEditor: stubComponent(MarkdownEditor, {
            template: '<div></div>',
            computed: {
              isContentEditorActive() {
                return false;
              },
            },
          }),
        });
        findEditor().vm.$emit('input', 'draft text');
        findEditor().vm.$emit(
          'keydown',
          new KeyboardEvent('keydown', { key: ENTER_KEY, shiftKey: true, metaKey: true }),
        );
        await nextTick();
        expect(saveDraft).toHaveBeenCalledWith('draft text');
        expect(defaultProps.saveNote).not.toHaveBeenCalled();
      });

      it('shows alert on draft save failure', async () => {
        const failingSaveDraft = jest.fn().mockRejectedValue({ response: null });
        createComponent({ saveDraft: failingSaveDraft, noteBody: 'test' }, undefined, {
          MarkdownEditor: stubComponent(MarkdownEditor, {
            template: '<div></div>',
            computed: {
              isContentEditorActive() {
                return false;
              },
            },
          }),
        });
        await findAddToReviewButton().vm.$emit('click');
        await nextTick();
        await nextTick();
        expect(createAlert).toHaveBeenCalled();
      });
    });
  });
});
