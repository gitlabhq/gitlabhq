import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { trimText } from 'helpers/text_helper';
import mockDiffFile from 'jest/diffs/mock_data/diff_file';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import NoteForm from '~/notes/components/note_form.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import createStore from '~/notes/stores';
import '~/behaviors/markdown/render_gfm';
import {
  noteableDataMock,
  discussionMock,
  notesDataMock,
  loggedOutnoteableData,
  userDataMock,
} from '../mock_data';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('noteable_discussion component', () => {
  let store;
  let wrapper;
  let originalGon;

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    wrapper = mount(NoteableDiscussion, {
      store,
      propsData: { discussion: discussionMock },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should not render thread header for non diff threads', () => {
    expect(wrapper.find('.discussion-header').exists()).toBe(false);
  });

  it('should render thread header', async () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = mockDiffFile;
    discussion.diff_discussion = true;
    discussion.expanded = false;

    wrapper.setProps({ discussion });
    await nextTick();

    expect(wrapper.find('.discussion-header').exists()).toBe(true);
  });

  it('should hide actions when diff refs do not exists', async () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = { ...mockDiffFile, diff_refs: null };
    discussion.diff_discussion = true;
    discussion.expanded = false;

    wrapper.setProps({ discussion });
    await nextTick();

    expect(wrapper.vm.canShowReplyActions).toBe(false);
  });

  describe('actions', () => {
    it('should toggle reply form', async () => {
      await nextTick();

      expect(wrapper.vm.isReplying).toEqual(false);

      const replyPlaceholder = wrapper.find(ReplyPlaceholder);
      replyPlaceholder.vm.$emit('focus');
      await nextTick();

      expect(wrapper.vm.isReplying).toEqual(true);

      const noteForm = wrapper.find(NoteForm);

      expect(noteForm.exists()).toBe(true);

      const noteFormProps = noteForm.props();

      expect(noteFormProps.discussion).toBe(discussionMock);
      expect(noteFormProps.isEditing).toBe(false);
      expect(noteFormProps.line).toBe(null);
      expect(noteFormProps.saveButtonTitle).toBe('Comment');
      expect(noteFormProps.autosaveKey).toBe(`Note/Issue/${discussionMock.id}/Reply`);
    });

    it('should expand discussion', async () => {
      const discussion = { ...discussionMock, expanded: false };

      wrapper.setProps({ discussion });
      store.dispatch = jest.fn();

      await nextTick();

      wrapper.find(DiscussionNotes).vm.$emit('startReplying');

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
  });

  describe('for resolved thread', () => {
    beforeEach(() => {
      const discussion = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
      wrapper.setProps({ discussion });
    });

    it('does not display a button to resolve with issue', () => {
      const button = wrapper.find(ResolveWithIssueButton);

      expect(button.exists()).toBe(false);
    });
  });

  describe('for unresolved thread', () => {
    beforeEach(() => {
      const discussion = {
        ...getJSONFixture(discussionWithTwoUnresolvedNotes)[0],
        expanded: true,
      };
      discussion.resolved = false;

      wrapper.setProps({ discussion });

      return nextTick();
    });

    it('displays a button to resolve with issue', () => {
      const button = wrapper.find(ResolveWithIssueButton);

      expect(button.exists()).toBe(true);
    });
  });

  describe('signout widget', () => {
    beforeEach(() => {
      originalGon = { ...window.gon };
      window.gon = window.gon || {};
    });

    afterEach(() => {
      wrapper.destroy();
      window.gon = originalGon;
    });

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
