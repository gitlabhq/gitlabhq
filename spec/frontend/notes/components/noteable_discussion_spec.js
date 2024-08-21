import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import discussionWithTwoUnresolvedNotes from 'test_fixtures/merge_requests/resolved_diff_discussion.json';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import NoteForm from '~/notes/components/note_form.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import { COMMENT_FORM } from '~/notes/i18n';
import notesModule from '~/notes/stores/modules';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';

import {
  noteableDataMock,
  discussionMock,
  notesDataMock,
  loggedOutnoteableData,
  userDataMock,
} from '../mock_data';
import { useLocalStorageSpy } from '../../__helpers__/local_storage_helper';

Vue.use(Vuex);

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/alert');

describe('noteable_discussion component', () => {
  let store;
  let wrapper;
  let axiosMock;

  const createStore = ({ saveNoteMock = jest.fn() } = {}) => {
    const baseModule = notesModule();

    return new Vuex.Store({
      ...baseModule,
      actions: {
        ...baseModule.actions,
        saveNote: saveNoteMock,
      },
    });
  };

  const createComponent = ({ storeMock = createStore(), discussion = discussionMock } = {}) => {
    store = storeMock;
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    wrapper = mountExtended(NoteableDiscussion, {
      store,
      propsData: { discussion },
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('should not render thread header for non diff threads', () => {
    expect(wrapper.find('.discussion-header').exists()).toBe(false);
  });

  it('should render thread header', async () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = getDiffFileMock();
    discussion.diff_discussion = true;
    discussion.expanded = false;

    wrapper.setProps({ discussion });
    await nextTick();

    expect(wrapper.find('.discussion-header').exists()).toBe(true);
  });

  it('should hide actions when diff refs do not exists', async () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = { ...getDiffFileMock(), diff_refs: null };
    discussion.diff_discussion = true;
    discussion.expanded = false;

    wrapper.setProps({ discussion });
    await nextTick();

    expect(wrapper.vm.canShowReplyActions).toBe(false);
  });

  describe('drafts', () => {
    useLocalStorageSpy();

    afterEach(() => {
      localStorage.clear();
    });

    it.each`
      show          | exists              | hasDraft
      ${'show'}     | ${'exists'}         | ${true}
      ${'not show'} | ${'does not exist'} | ${false}
    `(
      'should $show markdown editor on create if reply draft $exists in localStorage',
      ({ hasDraft }) => {
        if (hasDraft) {
          localStorage.setItem(`autosave/Note/Issue/${discussionMock.id}/Reply`, 'draft');
        }
        window.gon.current_user_id = userDataMock.id;
        store.dispatch('setUserData', userDataMock);
        wrapper = mount(NoteableDiscussion, {
          store,
          propsData: { discussion: discussionMock },
        });
        expect(wrapper.find('.note-edit-form').exists()).toBe(hasDraft);
      },
    );
  });

  describe('actions', () => {
    it('should toggle reply form', async () => {
      await nextTick();

      expect(wrapper.vm.isReplying).toEqual(false);

      const replyPlaceholder = wrapper.findComponent(DiscussionReplyPlaceholder);
      replyPlaceholder.vm.$emit('focus');
      await nextTick();

      expect(wrapper.vm.isReplying).toEqual(true);

      const noteForm = wrapper.findComponent(NoteForm);

      expect(noteForm.exists()).toBe(true);

      const noteFormProps = noteForm.props();

      expect(noteFormProps.discussion).toBe(discussionMock);
      expect(noteFormProps.line).toBe(null);
      expect(noteFormProps.autosaveKey).toBe(`Note/Issue/${discussionMock.id}/Reply`);
    });

    it.each`
      noteType      | isNoteInternal | saveButtonTitle
      ${'public'}   | ${false}       | ${'Reply'}
      ${'internal'} | ${true}        | ${'Reply internally'}
    `(
      'reply button on form should have title "$saveButtonTitle" when note is $noteType',
      async ({ isNoteInternal, saveButtonTitle }) => {
        wrapper.setProps({ discussion: { ...discussionMock, internal: isNoteInternal } });
        await nextTick();

        const replyPlaceholder = wrapper.findComponent(DiscussionReplyPlaceholder);
        replyPlaceholder.vm.$emit('focus');
        await nextTick();

        expect(wrapper.findComponent(NoteForm).props('saveButtonTitle')).toBe(saveButtonTitle);
      },
    );

    it('should expand discussion', async () => {
      const discussion = { ...discussionMock, expanded: false };

      wrapper.setProps({ discussion });
      store.dispatch = jest.fn();

      await nextTick();

      wrapper.findComponent(DiscussionNotes).vm.$emit('startReplying');

      await nextTick();

      expect(store.dispatch).toHaveBeenCalledWith('expandDiscussion', {
        discussionId: discussion.id,
      });
    });

    it('does not render jump to thread button', () => {
      expect(wrapper.find('*[data-original-title="Jump to next unresolved thread"]').exists()).toBe(
        false,
      );
    });

    it('should add `internal-note` class when the discussion is internal', async () => {
      const softCopyInternalNotes = [...discussionMock.notes];
      const mockInternalNotes = softCopyInternalNotes.splice(0, 2);
      mockInternalNotes[0].internal = true;

      const mockDiscussion = {
        ...discussionMock,
        notes: [...mockInternalNotes],
      };
      wrapper.setProps({ discussion: mockDiscussion });
      await nextTick();

      const replyWrapper = wrapper.find('[data-testid="reply-wrapper"]');
      expect(replyWrapper.exists()).toBe(true);
      expect(replyWrapper.classes('internal-note')).toBe(true);
    });
  });

  describe('for resolved thread', () => {
    beforeEach(() => {
      const discussion = discussionWithTwoUnresolvedNotes[0];
      wrapper.setProps({ discussion });
    });

    it('does not display a button to resolve with issue', () => {
      const button = wrapper.findComponent(ResolveWithIssueButton);

      expect(button.exists()).toBe(false);
    });
  });

  describe('for unresolved thread', () => {
    beforeEach(() => {
      const discussion = {
        ...discussionWithTwoUnresolvedNotes[0],
        expanded: true,
      };
      discussion.resolved = false;

      wrapper.setProps({ discussion });

      return nextTick();
    });

    it('displays a button to resolve with issue', () => {
      const button = wrapper.findComponent(ResolveWithIssueButton);

      expect(button.exists()).toBe(true);
    });
  });

  describe('save reply', () => {
    describe('if response contains validation errors', () => {
      beforeEach(async () => {
        const storeMock = createStore({
          saveNoteMock: jest.fn().mockRejectedValue({
            response: {
              status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
              data: { errors: 'error 1 and error 2' },
            },
          }),
        });

        createComponent({ storeMock });

        wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
        await nextTick();

        wrapper
          .findComponent(NoteForm)
          .vm.$emit('handleFormUpdate', 'invalid note', null, () => {});

        await waitForPromises();
      });

      it('renders an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: sprintf(COMMENT_FORM.error, { reason: 'error 1 and error 2' }),
          parent: wrapper.vm.$el,
        });
      });
    });
  });

  describe('signout widget', () => {
    describe('user is logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = userDataMock.id;
        store.dispatch('setUserData', userDataMock);

        wrapper = mount(NoteableDiscussion, {
          store,
          propsData: { discussion: discussionMock },
        });
      });

      it('should not render signed out widget', () => {
        expect(Boolean(wrapper.vm.isLoggedIn)).toBe(true);
        expect(trimText(wrapper.text())).not.toContain('Please register or sign in to reply');
      });
    });

    describe('user is not logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = null;
        store.dispatch('setNoteableData', loggedOutnoteableData);
        store.dispatch('setNotesData', notesDataMock);

        wrapper = mount(NoteableDiscussion, {
          store,
          propsData: { discussion: discussionMock },
        });
      });

      it('should render signed out widget', () => {
        expect(Boolean(wrapper.vm.isLoggedIn)).toBe(false);
        expect(trimText(wrapper.text())).toContain('Please register or sign in to reply');
      });
    });
  });
});
