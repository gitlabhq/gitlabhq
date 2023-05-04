import { GlLink, GlFormCheckbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import NoteForm from '~/notes/components/note_form.vue';
import createStore from '~/notes/stores';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { AT_WHO_ACTIVE_CLASS } from '~/gfm_auto_complete';
import eventHub from '~/environments/event_hub';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { noteableDataMock, notesDataMock, discussionMock, note } from '../mock_data';

jest.mock('~/lib/utils/autosave');

describe('issue_note_form component', () => {
  let store;
  let wrapper;
  let props;

  const createComponentWrapper = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(NoteForm, {
      store,
      propsData: {
        ...props,
        ...propsData,
      },
      provide: {
        glFeatures: provide,
      },
    });
  };

  const findCancelButton = () => wrapper.findByTestId('cancel');
  const findCancelCommentButton = () => wrapper.findByTestId('cancelBatchCommentsEnabled');
  const findMarkdownField = () => wrapper.findComponent(MarkdownField);

  beforeEach(() => {
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: '545',
    };
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

  it('hides content editor switcher if feature flag content_editor_on_issues is off', () => {
    createComponentWrapper({}, { contentEditorOnIssues: false });

    expect(wrapper.text()).not.toContain('Switch to rich text');
  });

  it('shows content editor switcher if feature flag content_editor_on_issues is on', () => {
    createComponentWrapper({}, { contentEditorOnIssues: true });

    expect(wrapper.text()).toContain('Switch to rich text');
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

    it('should render text area with placeholder', () => {
      const textarea = wrapper.find('textarea');

      expect(textarea.attributes('placeholder')).toBe('Write a comment or drag your files here…');
    });

    it('should set data-supports-quick-actions to enable autocomplete', () => {
      const textarea = wrapper.find('textarea');

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
      let textarea;

      beforeEach(() => {
        textarea = wrapper.find('textarea');
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

        const textarea = wrapper.find('textarea');
        textarea.setValue('Foo');
        const saveButton = wrapper.find('.js-vue-issue-save');
        saveButton.vm.$emit('click');

        expect(wrapper.emitted('handleFormUpdate')).toHaveLength(1);
      });
    });
  });

  describe('with batch comments', () => {
    beforeEach(() => {
      store.registerModule('batchComments', batchComments());

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

    it('shows resolve checkbox', () => {
      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
    });

    it('hides resolve checkbox', () => {
      createComponentWrapper({
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

      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(false);
    });

    it('hides actions for commits', () => {
      createComponentWrapper({ discussion: { for_commit: true } });

      expect(wrapper.find('.note-form-actions').text()).not.toContain('Start a review');
    });

    describe('on enter', () => {
      it('should start review or add to review when cmd+enter is pressed', async () => {
        const textarea = wrapper.find('textarea');

        textarea.setValue('Foo');
        textarea.trigger('keydown.enter', { metaKey: true });

        await nextTick();

        expect(wrapper.emitted('handleFormUpdateAddToReview')).toEqual([['Foo', false]]);
      });
    });
  });
});
