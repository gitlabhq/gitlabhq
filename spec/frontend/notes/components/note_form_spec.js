import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import { getDraft, updateDraft } from '~/lib/utils/autosave';
import NoteForm from '~/notes/components/note_form.vue';
import createStore from '~/notes/stores';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { noteableDataMock, notesDataMock, discussionMock } from '../mock_data';

jest.mock('~/lib/utils/autosave');

describe('issue_note_form component', () => {
  const dummyAutosaveKey = 'some-autosave-key';
  const dummyDraft = 'dummy draft content';

  let store;
  let wrapper;
  let props;

  const createComponentWrapper = () => {
    return mount(NoteForm, {
      store,
      propsData: props,
    });
  };

  const findCancelButton = () => wrapper.find('[data-testid="cancel"]');

  beforeEach(() => {
    getDraft.mockImplementation((key) => {
      if (key === dummyAutosaveKey) {
        return dummyDraft;
      }

      return null;
    });

    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: '545',
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('noteHash', () => {
    beforeEach(() => {
      wrapper = createComponentWrapper();
    });

    it('returns note hash string based on `noteId`', () => {
      expect(wrapper.vm.noteHash).toBe(`#note_${props.noteId}`);
    });

    it('return note hash as `#` when `noteId` is empty', async () => {
      wrapper.setProps({
        ...props,
        noteId: '',
      });
      await nextTick();

      expect(wrapper.vm.noteHash).toBe('#');
    });
  });

  describe('conflicts editing', () => {
    beforeEach(() => {
      wrapper = createComponentWrapper();
    });

    it('should show conflict message if note changes outside the component', async () => {
      wrapper.setProps({
        ...props,
        isEditing: true,
        noteBody: 'Foo',
      });

      const message =
        'This comment changed after you started editing it. Review the updated comment to ensure information is not lost.';

      await nextTick();

      const conflictWarning = wrapper.find('.js-conflict-edit-warning');

      expect(conflictWarning.exists()).toBe(true);
      expect(conflictWarning.text().replace(/\s+/g, ' ').trim()).toBe(message);
    });
  });

  describe('form', () => {
    beforeEach(() => {
      wrapper = createComponentWrapper();
    });

    it('should render text area with placeholder', () => {
      const textarea = wrapper.find('textarea');

      expect(textarea.attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });

    it('should link to markdown docs', () => {
      const { markdownDocsPath } = notesDataMock;
      const markdownField = wrapper.find(MarkdownField);
      const markdownFieldProps = markdownField.props();

      expect(markdownFieldProps.markdownDocsPath).toBe(markdownDocsPath);
    });

    describe('keyboard events', () => {
      let textarea;

      beforeEach(() => {
        textarea = wrapper.find('textarea');
        textarea.setValue('Foo');
      });

      describe('up', () => {
        it('should ender edit mode', () => {
          // TODO: do not spy on vm
          jest.spyOn(wrapper.vm, 'editMyLastNote');

          textarea.trigger('keydown.up');

          expect(wrapper.vm.editMyLastNote).toHaveBeenCalled();
        });
      });

      describe('enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          textarea.trigger('keydown.enter', { metaKey: true });

          const { handleFormUpdate } = wrapper.emitted();

          expect(handleFormUpdate.length).toBe(1);
        });

        it('should save note when ctrl+enter is pressed', () => {
          textarea.trigger('keydown.enter', { ctrlKey: true });

          const { handleFormUpdate } = wrapper.emitted();

          expect(handleFormUpdate.length).toBe(1);
        });
      });
    });

    describe('actions', () => {
      it('should be possible to cancel', async () => {
        wrapper.setProps({
          ...props,
          isEditing: true,
        });
        await nextTick();

        const cancelButton = findCancelButton();
        cancelButton.vm.$emit('click');
        await nextTick();

        expect(wrapper.emitted().cancelForm).toHaveLength(1);
      });

      it('should be possible to update the note', async () => {
        wrapper.setProps({
          ...props,
          isEditing: true,
        });
        await nextTick();

        const textarea = wrapper.find('textarea');
        textarea.setValue('Foo');
        const saveButton = wrapper.find('.js-vue-issue-save');
        saveButton.vm.$emit('click');

        expect(wrapper.vm.isSubmitting).toBe(true);
      });
    });
  });

  describe('with autosaveKey', () => {
    describe('with draft', () => {
      beforeEach(() => {
        Object.assign(props, {
          noteBody: '',
          autosaveKey: dummyAutosaveKey,
        });
        wrapper = createComponentWrapper();

        return nextTick();
      });

      it('displays the draft in textarea', () => {
        const textarea = wrapper.find('textarea');

        expect(textarea.element.value).toBe(dummyDraft);
      });
    });

    describe('without draft', () => {
      beforeEach(() => {
        Object.assign(props, {
          noteBody: '',
          autosaveKey: 'some key without draft',
        });
        wrapper = createComponentWrapper();

        return nextTick();
      });

      it('leaves the textarea empty', () => {
        const textarea = wrapper.find('textarea');

        expect(textarea.element.value).toBe('');
      });
    });

    it('updates the draft if textarea content changes', () => {
      Object.assign(props, {
        noteBody: '',
        autosaveKey: dummyAutosaveKey,
      });
      wrapper = createComponentWrapper();
      const textarea = wrapper.find('textarea');
      const dummyContent = 'some new content';

      textarea.setValue(dummyContent);

      expect(updateDraft).toHaveBeenCalledWith(dummyAutosaveKey, dummyContent);
    });

    it('does not save draft when ctrl+enter is pressed', () => {
      const options = {
        noteBody: '',
        autosaveKey: dummyAutosaveKey,
      };

      props = { ...props, ...options };
      wrapper = createComponentWrapper();

      wrapper.setData({ isSubmittingWithKeydown: true });

      const textarea = wrapper.find('textarea');
      textarea.setValue('some content');
      textarea.trigger('keydown.enter', { metaKey: true });

      expect(updateDraft).not.toHaveBeenCalled();
    });
  });

  describe('with batch comments', () => {
    beforeEach(() => {
      store.registerModule('batchComments', batchComments());

      wrapper = createComponentWrapper();
      wrapper.setProps({
        ...props,
        isDraft: true,
        noteId: '',
        discussion: { ...discussionMock, for_commit: false },
      });
    });

    it('should be possible to cancel', async () => {
      jest.spyOn(wrapper.vm, 'cancelHandler');

      await nextTick();
      const cancelButton = wrapper.find('[data-testid="cancelBatchCommentsEnabled"]');
      cancelButton.vm.$emit('click');

      expect(wrapper.vm.cancelHandler).toHaveBeenCalledWith(true);
    });

    it('shows resolve checkbox', () => {
      expect(wrapper.find('.js-resolve-checkbox').exists()).toBe(true);
    });

    it('hides resolve checkbox', async () => {
      wrapper.setProps({
        isDraft: false,
        discussion: {
          ...discussionMock,
          notes: [
            ...discussionMock.notes.map((n) => ({
              ...n,
              resolvable: true,
              current_user: { ...n.current_user, can_resolve_discussion: false },
            })),
          ],
          for_commit: false,
        },
      });

      await nextTick();

      expect(wrapper.find('.js-resolve-checkbox').exists()).toBe(false);
    });

    it('hides actions for commits', async () => {
      wrapper.setProps({ discussion: { for_commit: true } });

      await nextTick();

      expect(wrapper.find('.note-form-actions').text()).not.toContain('Start a review');
    });

    describe('on enter', () => {
      it('should start review or add to review when cmd+enter is pressed', async () => {
        const textarea = wrapper.find('textarea');

        jest.spyOn(wrapper.vm, 'handleAddToReview');

        textarea.setValue('Foo');
        textarea.trigger('keydown.enter', { metaKey: true });

        await nextTick();
        expect(wrapper.vm.handleAddToReview).toHaveBeenCalled();
      });
    });
  });
});
