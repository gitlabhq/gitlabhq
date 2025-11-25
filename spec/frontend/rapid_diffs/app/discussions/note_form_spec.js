import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { ARROW_UP_KEY, ENTER_KEY, ESC_KEY } from '~/lib/utils/keys';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/vue_shared/components/markdown/tracking');

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
    wrapper = shallowMount(NoteForm, {
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
  const findCancelButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((buttonWrapper) => buttonWrapper.text() === 'Cancel')
      .at(0);

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
      expect(wrapper.emitted('cancel')).toStrictEqual([[true, false]]);
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
        expect(wrapper.emitted('cancel')).toStrictEqual([[false, false]]);
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

    it('cancels form', () => {
      createComponent();
      findCancelButton().vm.$emit('click');
      expect(wrapper.emitted('cancel')).toStrictEqual([[true, false]]);
    });

    it('cancels form with edited text', () => {
      createComponent();
      findEditor().vm.$emit('input', 'edit');
      findCancelButton().vm.$emit('click');
      expect(wrapper.emitted('cancel')).toStrictEqual([[true, true]]);
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
});
