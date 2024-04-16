import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { clearDraft } from '~/lib/utils/autosave';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import createNoteMutation from '~/work_items/graphql/notes/create_work_item_note.mutation.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import {
  createWorkItemNoteResponse,
  groupWorkItemByIidResponseFactory,
  workItemByIidResponseFactory,
  workItemQueryResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

const workItemId = workItemQueryResponse.data.workItem.id;

describe('Work item add note', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(createWorkItemNoteResponse);
  let workItemResponseHandler;
  let groupWorkItemResponseHandler;

  const findCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findReplyPlaceholder = () => wrapper.findComponent(DiscussionReplyPlaceholder);
  const findWorkItemLockedComponent = () => wrapper.findComponent(WorkItemCommentLocked);

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    canCreateNote = true,
    workItemIid = '1',
    workItemResponse = workItemByIidResponseFactory({ canUpdate, canCreateNote }),
    groupWorkItemResponse = groupWorkItemByIidResponseFactory({ canUpdate, canCreateNote }),
    signedIn = true,
    isEditing = true,
    isGroup = false,
    workItemType = 'Task',
    isInternalThread = false,
  } = {}) => {
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);
    groupWorkItemResponseHandler = jest.fn().mockResolvedValue(groupWorkItemResponse);
    if (signedIn) {
      window.gon.current_user_id = '1';
      window.gon.current_user_avatar_url = 'avatar.png';
    }

    const { id } = workItemQueryResponse.data.workItem;
    wrapper = shallowMountExtended(WorkItemAddNote, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemResponseHandler],
        [groupWorkItemByIidQuery, groupWorkItemResponseHandler],
        [createNoteMutation, mutationHandler],
      ]),
      provide: {
        isGroup,
      },
      propsData: {
        fullPath: 'test-project-path',
        workItemId: id,
        workItemIid,
        workItemType,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
        isInternalThread,
      },
      stubs: {
        WorkItemCommentLocked,
      },
    });

    await waitForPromises();

    if (isEditing) {
      findReplyPlaceholder().vm.$emit('focus');
    }
  };

  describe('adding a comment', () => {
    describe.each`
      isInternalComment
      ${false}
      ${true}
    `('when internal comment is $isInternalComment', ({ isInternalComment }) => {
      it('calls update widgets mutation', async () => {
        const noteText = 'updated desc';

        await createComponent({
          isEditing: true,
          signedIn: true,
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: noteText,
          isNoteInternal: isInternalComment,
        });

        await waitForPromises();

        expect(mutationSuccessHandler).toHaveBeenCalledWith({
          input: {
            noteableId: workItemId,
            body: noteText,
            discussionId: null,
            internal: isInternalComment,
          },
        });
      });

      it('tracks adding comment', async () => {
        await createComponent();
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'test',
          isNoteInternal: isInternalComment,
        });

        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'add_work_item_comment', {
          category: TRACKING_CATEGORY_SHOW,
          label: 'item_comment',
          property: 'type_Task',
        });
      });

      it('emits `replied` event and hides form after successful mutation', async () => {
        await createComponent({ isEditing: true, signedIn: true });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'some text',
          isNoteInternal: isInternalComment,
        });
        await waitForPromises();

        expect(wrapper.emitted('replied')).toEqual([[]]);
      });

      it('clears a draft after successful mutation', async () => {
        await createComponent({
          isEditing: true,
          signedIn: true,
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'some text',
          isNoteInternal: isInternalComment,
        });
        await waitForPromises();

        expect(clearDraft).toHaveBeenCalledWith('gid://gitlab/WorkItem/1-comment');
      });

      it('emits error when mutation returns error', async () => {
        const error = 'eror';

        await createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockResolvedValue({
            data: {
              createNote: {
                note: {
                  id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                  discussion: {
                    id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                    notes: {
                      nodes: [],
                      __typename: 'NoteConnection',
                    },
                    __typename: 'Discussion',
                  },
                  __typename: 'Note',
                },
                __typename: 'CreateNotePayload',
                errors: [error],
              },
            },
          }),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'updated desc',
          isNoteInternal: isInternalComment,
        });

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('emits error when mutation fails', async () => {
        const error = 'eror';

        await createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockRejectedValue(new Error(error)),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'updated desc',
          isNoteInternal: isInternalComment,
        });

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('ignores errors when mutation returns additional information as errors for quick actions', async () => {
        await createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockResolvedValue({
            data: {
              createNote: {
                note: {
                  id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                  discussion: {
                    id: 'gid://gitlab/Discussion/c872ba2d7d3eb780d2255138d67ca8b04f65b122',
                    notes: {
                      nodes: [],
                      __typename: 'NoteConnection',
                    },
                    __typename: 'Discussion',
                  },
                  __typename: 'Note',
                },
                __typename: 'CreateNotePayload',
                errors: ['Commands only Removed assignee @foobar.', 'Command names ["unassign"]'],
              },
            },
          }),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'updated desc',
          isNoteInternal: isInternalComment,
        });

        await waitForPromises();

        expect(clearDraft).toHaveBeenCalledWith('gid://gitlab/WorkItem/1-comment');
      });

      it('emits error to parent when the comment form emits error', async () => {
        await createComponent({ isEditing: true, signedIn: true });
        const error = 'error';
        findCommentForm().vm.$emit('error', error);

        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('sends confidential prop to work item comment form', async () => {
        await createComponent({ isEditing: true, signedIn: true });

        const {
          data: {
            workspace: {
              workItems: { nodes },
            },
          },
        } = workItemByIidResponseFactory({ canUpdate: true, canCreateNote: true });

        expect(findCommentForm().props('isWorkItemConfidential')).toBe(nodes[0].confidential);
      });
    });
  });

  describe('when project context', () => {
    it('calls the project work item query', async () => {
      await createComponent();

      expect(workItemResponseHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query', async () => {
      await createComponent();

      expect(groupWorkItemResponseHandler).not.toHaveBeenCalled();
    });

    it('skips calling the project work item query when missing workItemIid', async () => {
      await createComponent({ workItemIid: '', isEditing: false });

      expect(workItemResponseHandler).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    it('skips calling the project work item query', async () => {
      await createComponent({ isGroup: true });

      expect(workItemResponseHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query', async () => {
      await createComponent({ isGroup: true });

      expect(groupWorkItemResponseHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query when missing workItemIid', async () => {
      await createComponent({ isGroup: true, workItemIid: '', isEditing: false });

      expect(groupWorkItemResponseHandler).not.toHaveBeenCalled();
    });
  });

  it('wrapper adds `internal-note` class when internal thread', async () => {
    await createComponent({ isInternalThread: true });

    expect(wrapper.attributes('class')).toContain('internal-note');
  });

  describe('when work item`createNote` permission false', () => {
    it('cannot add comment', async () => {
      await createComponent({ isEditing: false, canCreateNote: false });

      expect(findWorkItemLockedComponent().exists()).toBe(true);
      expect(findCommentForm().exists()).toBe(false);
    });
  });
});
