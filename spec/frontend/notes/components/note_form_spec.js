import { GlLink, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import NoteForm from '~/notes/components/note_form.vue';
import createStore from '~/notes/stores';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import { AT_WHO_ACTIVE_CLASS } from '~/gfm_auto_complete';
import eventHub from '~/environments/event_hub';
import notesEventHub from '~/notes/event_hub';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { noteableDataMock, notesDataMock, discussionMock, note } from '../mock_data';

jest.mock('~/lib/utils/autosave');

Vue.use(PiniaVuePlugin);

describe('issue_note_form component', () => {
  let store;
  let pinia;
  let wrapper;
  let textarea;
  let props;
  let trackingSpy;

  const createComponentWrapper = (propsData = {}, provide = {}, stubs = {}) => {
    wrapper = mountExtended(NoteForm, {
      store,
      pinia,
      propsData: {
        ...props,
        ...propsData,
      },
      provide: {
        glFeatures: provide,
      },
      mocks: {
        $apollo: {
          queries: {
            currentUser: {
              loading: false,
            },
          },
        },
      },
      stubs,
    });

    textarea = wrapper.find('textarea');
  };

  const findCancelButton = () => wrapper.findByTestId('cancel');
  const findCancelCommentButton = () => wrapper.findByTestId('cancelBatchCommentsEnabled');
  const findAddToStartReviewButton = () => wrapper.findByTestId('start-review-button');
  const findMarkdownField = () => wrapper.findComponent(MarkdownField);

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments().$patch({ isMergeRequest: true });

    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: '545',
    };
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe('noteHash', () => {
    beforeEach(() => {
      createComponentWrapper();
    });

    it('returns note hash string based on `noteId`', () => {
      expect(wrapper.vm.noteHash).toBe(`#note_${props.noteId}`);
    });

    it('return note hash as `#` when `noteId` is empty', () => {
      createComponentWrapper({
        noteId: '',
      });

      expect(wrapper.vm.noteHash).toBe('#');
    });
  });

  it('shows content editor switcher', () => {
    createComponentWrapper();

    expect(wrapper.text()).toContain('Switch to rich text editing');
  });

  describe('conflicts editing', () => {
    beforeEach(() => {
      createComponentWrapper();
    });

    it('should show conflict message if note changes outside the component', async () => {
      wrapper.setProps({
        ...props,
        noteBody: 'Foo',
      });

      const message =
        'This comment changed after you started editing it. Review the updated comment to ensure information is not lost.';

      await nextTick();

      const conflictWarning = wrapper.find('.js-conflict-edit-warning');

      expect(conflictWarning.exists()).toBe(true);
      expect(conflictWarning.text().replace(/\s+/g, ' ').trim()).toBe(message);
      expect(conflictWarning.findComponent(GlLink).attributes('href')).toBe('#note_545');
    });
  });

  describe('form', () => {
    beforeEach(() => {
      createComponentWrapper();
    });

    it('should render text area with noteable type', () => {
      expect(textarea.attributes('data-noteable-type')).toBe(noteableDataMock.noteableType);
    });

    it('should render text area with placeholder', () => {
      expect(textarea.attributes('placeholder')).toBe('Write a comment or drag your files here…');
    });

    it('should set data-supports-quick-actions to enable autocomplete', () => {
      expect(textarea.attributes('data-supports-quick-actions')).toBe('true');
    });

    it.each`
      internal | placeholder
      ${false} | ${'Write a comment or drag your files here…'}
      ${true}  | ${'Write an internal note or drag your files here…'}
    `(
      'should set correct textarea placeholder text when discussion confidentiality is $internal',
      async ({ internal, placeholder }) => {
        props.note = {
          ...note,
          internal,
        };
        createComponentWrapper();

        await nextTick();

        expect(wrapper.find('textarea').attributes('placeholder')).toBe(placeholder);
      },
    );

    it('should link to markdown docs', () => {
      expect(findMarkdownField().props('markdownDocsPath')).toBe(notesDataMock.markdownDocsPath);
    });

    describe('keyboard events', () => {
      beforeEach(() => {
        textarea.setValue('Foo');
      });

      describe('up', () => {
        it('should ender edit mode', () => {
          const eventHubSpy = jest.spyOn(eventHub, '$emit');

          textarea.trigger('keydown.up');

          expect(eventHubSpy).not.toHaveBeenCalled();
        });
      });

      describe('enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          textarea.trigger('keydown.enter', { metaKey: true });

          expect(wrapper.emitted('handleFormUpdate')).toHaveLength(1);
        });

        it('should save note when ctrl+enter is pressed', () => {
          textarea.trigger('keydown.enter', { ctrlKey: true });

          expect(wrapper.emitted('handleFormUpdate')).toHaveLength(1);
        });

        it('should disable textarea when ctrl+enter is pressed', async () => {
          textarea.trigger('keydown.enter', { ctrlKey: true });

          expect(textarea.attributes('disabled')).toBeUndefined();

          await nextTick();

          expect(textarea.attributes('disabled')).toBeDefined();
        });
      });
    });

    describe('actions', () => {
      it('should be possible to cancel', () => {
        createComponentWrapper();

        findCancelButton().vm.$emit('click');

        expect(wrapper.emitted('cancelForm')).toHaveLength(1);
      });

      it('will not cancel form if there is an active at-who-active class', async () => {
        createComponentWrapper();

        const textareaEl = wrapper.vm.$refs.markdownEditor.$el.querySelector('textarea');
        const cancelButton = findCancelButton();
        textareaEl.classList.add(AT_WHO_ACTIVE_CLASS);
        cancelButton.vm.$emit('click');
        await nextTick();

        expect(wrapper.emitted('cancelForm')).toBeUndefined();
      });

      it('should be possible to update the note', () => {
        createComponentWrapper();

        textarea.setValue('Foo');
        const saveButton = wrapper.find('.js-vue-issue-save');
        saveButton.vm.$emit('click');

        expect(wrapper.emitted('handleFormUpdate')).toHaveLength(1);
      });

      it('tracks event when save button is clicked', () => {
        createComponentWrapper();

        textarea.setValue('Foo');
        const saveButton = wrapper.find('.js-vue-issue-save');
        saveButton.vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
          label: 'markdown_editor',
          property: 'Issue_note',
        });
      });

      describe('when discussion is internal', () => {
        beforeEach(() => {
          createComponentWrapper({ note: { internal: true } });
        });

        it('passes correct internal note information to CommentFieldLayout', () => {
          expect(wrapper.findComponent(CommentFieldLayout).props('isInternalNote')).toBe(true);
        });
      });
    });
  });

  describe('resolve checkbox', () => {
    it('hides resolve checkbox when discussion is not resolvable', () => {
      createComponentWrapper({
        discussion: {
          ...discussionMock,
          notes: [
            ...discussionMock.notes.map((n) => ({
              ...n,
              resolvable: false,
              current_user: { ...n.current_user, can_resolve_discussion: false },
            })),
          ],
        },
      });

      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(false);
    });

    it('shows resolve checkbox when discussion is resolvable', () => {
      createComponentWrapper({
        discussion: {
          ...discussionMock,
          notes: [
            ...discussionMock.notes.map((n) => ({
              ...n,
              resolvable: true,
              current_user: { ...n.current_user, can_resolve_discussion: true },
            })),
          ],
        },
      });

      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
    });
  });

  describe('with batch comments', () => {
    beforeEach(() => {
      createComponentWrapper({
        isDraft: true,
        noteId: '',
        discussion: { ...discussionMock, for_commit: false },
      });
    });

    it('should be possible to cancel', () => {
      findCancelCommentButton().vm.$emit('click');

      expect(wrapper.emitted('cancelForm')).toEqual([[true, false]]);
    });

    it('hides actions for commits', () => {
      createComponentWrapper({ discussion: { for_commit: true } });

      expect(wrapper.find('.note-form-actions').text()).not.toContain('Start a review');
    });

    describe('on enter', () => {
      it('should start review or add to review when cmd+enter is pressed', async () => {
        textarea.setValue('Foo');
        textarea.trigger('keydown.enter', { metaKey: true });

        await nextTick();

        expect(wrapper.emitted('handleFormUpdateAddToReview')).toStrictEqual([
          ['Foo', false, wrapper.vm.$refs.editNoteForm, expect.any(Function)],
        ]);
      });
    });

    describe('on shift cmd enter', () => {
      it('should add comment now when shift-cmd+enter is pressed', async () => {
        textarea.setValue('Foo');
        textarea.trigger('keydown.enter', { metaKey: true, shiftKey: true });

        await nextTick();

        expect(wrapper.emitted('handleFormUpdate')).toHaveLength(1);
      });
    });

    describe('when adding a draft comment', () => {
      beforeEach(() => {
        jest.spyOn(notesEventHub, '$emit');
      });

      it('sends the event to indicate that a draft has been added to the review', () => {
        useBatchComments().drafts = [{ note: 'A' }];
        createComponentWrapper({
          isDraft: true,
          noteId: '',
          discussion: { ...discussionMock, for_commit: false },
        });

        findAddToStartReviewButton().trigger('click');

        expect(notesEventHub.$emit).toHaveBeenCalledWith('noteFormAddToReview', {
          name: 'noteFormAddToReview',
        });
      });

      it('sends the event to indicate that a review has been started with the new draft', () => {
        createComponentWrapper({
          isDraft: true,
          noteId: '',
          discussion: { ...discussionMock, for_commit: false },
        });

        findAddToStartReviewButton().trigger('click');

        expect(notesEventHub.$emit).toHaveBeenCalledWith('noteFormStartReview', {
          name: 'noteFormStartReview',
        });
      });
    });
  });

  it('calls append on a markdown editor', () => {
    createComponentWrapper(undefined, undefined, { MarkdownEditor });
    const spy = jest.spyOn(wrapper.findComponent(MarkdownEditor).vm, 'append');
    wrapper.vm.append('foo');
    expect(spy).toHaveBeenCalledWith('foo');
  });
});
