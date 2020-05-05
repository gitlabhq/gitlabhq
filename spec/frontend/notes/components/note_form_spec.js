import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import NoteForm from '~/notes/components/note_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { noteableDataMock, notesDataMock } from '../mock_data';

import { getDraft, updateDraft } from '~/lib/utils/autosave';

jest.mock('~/lib/utils/autosave');

describe('issue_note_form component', () => {
  const dummyAutosaveKey = 'some-autosave-key';
  const dummyDraft = 'dummy draft content';

  let store;
  let wrapper;
  let props;

  const createComponentWrapper = () => {
    const localVue = createLocalVue();
    return shallowMount(localVue.extend(NoteForm), {
      store,
      propsData: props,
      // see https://gitlab.com/gitlab-org/gitlab-foss/issues/56317 for the following
      localVue,
    });
  };

  beforeEach(() => {
    getDraft.mockImplementation(key => {
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

    it('return note hash as `#` when `noteId` is empty', () => {
      wrapper.setProps({
        ...props,
        noteId: '',
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.noteHash).toBe('#');
      });
    });
  });

  describe('conflicts editing', () => {
    beforeEach(() => {
      wrapper = createComponentWrapper();
    });

    it('should show conflict message if note changes outside the component', () => {
      wrapper.setProps({
        ...props,
        isEditing: true,
        noteBody: 'Foo',
      });

      const message =
        'This comment has changed since you started editing, please review the updated comment to ensure information is not lost.';

      return wrapper.vm.$nextTick().then(() => {
        const conflictWarning = wrapper.find('.js-conflict-edit-warning');

        expect(conflictWarning.exists()).toBe(true);
        expect(
          conflictWarning
            .text()
            .replace(/\s+/g, ' ')
            .trim(),
        ).toBe(message);
      });
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
      it('should be possible to cancel', () => {
        const cancelHandler = jest.fn();
        wrapper.setProps({
          ...props,
          isEditing: true,
        });
        wrapper.setMethods({ cancelHandler });

        return wrapper.vm.$nextTick().then(() => {
          const cancelButton = wrapper.find('[data-testid="cancel"]');
          cancelButton.trigger('click');

          expect(cancelHandler).toHaveBeenCalledWith(true);
        });
      });

      it('should be possible to update the note', () => {
        wrapper.setProps({
          ...props,
          isEditing: true,
        });

        return wrapper.vm.$nextTick().then(() => {
          const textarea = wrapper.find('textarea');
          textarea.setValue('Foo');
          const saveButton = wrapper.find('.js-vue-issue-save');
          saveButton.trigger('click');

          expect(wrapper.vm.isSubmitting).toBe(true);
        });
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

        return wrapper.vm.$nextTick();
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

        return wrapper.vm.$nextTick();
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
  });
});
