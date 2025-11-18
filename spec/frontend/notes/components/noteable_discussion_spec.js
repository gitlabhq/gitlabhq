import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
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
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import {
  discussionMock,
  notesDataMock,
  loggedOutnoteableData,
  userDataMock,
  noteableDataMock,
} from '../mock_data';
import { useLocalStorageSpy } from '../../__helpers__/local_storage_helper';

Vue.use(PiniaVuePlugin);

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/behaviors/markdown/copy_as_gfm');
jest.mock('~/alert');

function createPinia({ stubActions = true } = {}) {
  const pinia = createTestingPinia({ stubActions, plugins: [globalAccessorPlugin] });
  const diffsStore = useLegacyDiffs();
  useNotes().noteableData = noteableDataMock;
  useNotes().notesData = notesDataMock;
  useNotes().saveNote.mockResolvedValue();
  useNotes().fetchDiscussionDiffLines.mockResolvedValue();
  useBatchComments();

  return { pinia, diffsStore };
}

describe('noteable_discussion component', () => {
  let pinia;
  let wrapper;
  let axiosMock;
  let diffsStore;

  const createComponent = ({ discussion = discussionMock } = {}) => {
    wrapper = mountExtended(NoteableDiscussion, {
      pinia,
      propsData: { discussion },
    });
  };

  const findReplyWrapper = () => wrapper.findByTestId('reply-wrapper');

  beforeEach(() => {
    localStorage.clear();
    ({ pinia, diffsStore } = createPinia());
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

  describe('when diff discussion does not have a diff_file', () => {
    it.each`
      positionType
      ${'file'}
      ${'image'}
    `('should show reply actions when position_type is $positionType', async ({ positionType }) => {
      const discussion = { ...discussionMock, original_position: { position_type: positionType } };
      discussion.diff_file = { ...getDiffFileMock(), diff_refs: null };
      discussion.diff_discussion = true;

      wrapper.setProps({ discussion });
      await nextTick();

      expect(findReplyWrapper().exists()).toBe(true);
    });
  });

  describe('when user is logged in', () => {
    beforeEach(() => {
      window.gon.current_user_id = 1;
    });

    describe('when user can reply', () => {
      beforeEach(() => {
        useNotes().noteableData = { ...noteableDataMock, current_user: { can_create_note: true } };
      });

      it('renders reply wrapper', () => {
        createComponent();

        expect(findReplyWrapper().exists()).toBe(true);
      });

      it('quotes reply', async () => {
        jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => cb());
        CopyAsGFM.selectionToGfm.mockResolvedValue('foo');
        createComponent();
        wrapper.element
          .querySelector('.js-discussion-container')
          .dispatchEvent(new CustomEvent('quoteReply'));
        // wait for selectionToGfm
        await waitForPromises();
        // requestAnimationFrame executed immediately
        // wait for markdown_editor.vue to update
        await nextTick();
        expect(wrapper.element.querySelector('[data-testid="reply-field"]').value).toBe('foo\n\n');
      });
    });

    describe('when user cannot reply', () => {
      it('does not render reply wrapper', () => {
        useNotes().noteableData = { ...noteableDataMock, current_user: { can_create_note: false } };

        createComponent();

        expect(findReplyWrapper().exists()).toBe(false);
      });
    });
  });

  describe('when user is not logged in', () => {
    beforeEach(() => {
      window.gon.current_user_id = null;
    });

    it('renders reply wrapper', () => {
      createComponent();

      expect(findReplyWrapper().exists()).toBe(true);
    });
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
        wrapper = mount(NoteableDiscussion, {
          pinia,
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

      await nextTick();

      wrapper.findComponent(DiscussionNotes).vm.$emit('startReplying');

      await nextTick();

      expect(useNotes().expandDiscussion).toHaveBeenCalledWith({
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
        useNotes().saveNote.mockRejectedValue({
          response: {
            status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
            data: { errors: 'error 1 and error 2' },
          },
        });

        createComponent();

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

        wrapper = mount(NoteableDiscussion, {
          pinia,
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
        useNotes().noteableData = loggedOutnoteableData;

        wrapper = mount(NoteableDiscussion, {
          pinia,
          propsData: { discussion: discussionMock },
        });
      });

      it('should render signed out widget', () => {
        expect(Boolean(wrapper.vm.isLoggedIn)).toBe(false);
        expect(trimText(wrapper.text())).toContain('Please register or sign in to reply');
      });
    });
  });

  it('includes the original line range when replying', async () => {
    wrapper.vm.showReplyForm();

    await nextTick();

    const form = wrapper.findComponent(NoteForm);

    expect(form.props('lines')).toEqual([]);
  });

  describe('multi-line comments', () => {
    let discussion;
    let startCode;
    let endCode;

    beforeEach(() => {
      ({ pinia, diffsStore } = createPinia({ stubActions: false }));

      const file = getDiffFileMock();
      diffsStore.diffFiles = [file];

      startCode = file.highlighted_diff_lines[6].line_code;
      endCode = file.highlighted_diff_lines[7].line_code;

      discussion = {
        ...discussionMock,
        diff_file: file,
        position: {
          line_range: {
            start: {
              line_code: startCode,
            },
            end: {
              line_code: endCode,
            },
          },
        },
      };

      createComponent({ discussion });
    });

    it('includes the original line range when replying to a multiline comment', async () => {
      wrapper.vm.showReplyForm();
      await nextTick();

      const form = wrapper.findComponent(NoteForm);

      expect(form.props('lines')).toEqual([
        expect.objectContaining({ line_code: startCode }),
        expect.objectContaining({ line_code: endCode }),
      ]);
    });
  });
});
