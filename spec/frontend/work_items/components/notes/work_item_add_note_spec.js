import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { clearDraft } from '~/lib/utils/autosave';
import { config } from '~/graphql_shared/issuable_client';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import createNoteMutation from '~/work_items/graphql/notes/create_work_item_note.mutation.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemNotesQuery from '~/work_items/graphql/notes/work_item_notes.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  workItemResponseFactory,
  workItemQueryResponse,
  projectWorkItemResponse,
  createWorkItemNoteResponse,
  mockWorkItemNotesResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

const workItemId = workItemQueryResponse.data.workItem.id;

describe('Work item add note', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(createWorkItemNoteResponse);
  const workItemByIidResponseHandler = jest.fn().mockResolvedValue(projectWorkItemResponse);
  let workItemResponseHandler;

  const findCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findTextarea = () => wrapper.findByTestId('note-reply-textarea');

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    workItemResponse = workItemResponseFactory({ canUpdate }),
    queryVariables = { id: workItemId },
    fetchByIid = false,
    signedIn = true,
    isEditing = true,
    workItemType = 'Task',
  } = {}) => {
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);
    if (signedIn) {
      window.gon.current_user_id = '1';
      window.gon.current_user_avatar_url = 'avatar.png';
    }

    const apolloProvider = createMockApollo(
      [
        [workItemQuery, workItemResponseHandler],
        [createNoteMutation, mutationHandler],
        [workItemByIidQuery, workItemByIidResponseHandler],
      ],
      {},
      { ...config.cacheConfig },
    );

    apolloProvider.clients.defaultClient.writeQuery({
      query: workItemNotesQuery,
      variables: {
        id: workItemId,
        pageSize: 100,
      },
      data: mockWorkItemNotesResponse.data,
    });

    const { id } = workItemQueryResponse.data.workItem;
    wrapper = shallowMountExtended(WorkItemAddNote, {
      apolloProvider,
      propsData: {
        workItemId: id,
        fullPath: 'test-project-path',
        queryVariables,
        fetchByIid,
        workItemType,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
      },
      stubs: {
        WorkItemCommentLocked,
      },
    });

    await waitForPromises();

    if (isEditing) {
      findTextarea().trigger('click');
    }
  };

  describe('adding a comment', () => {
    it('calls update widgets mutation', async () => {
      const noteText = 'updated desc';

      await createComponent({
        isEditing: true,
        signedIn: true,
      });

      findCommentForm().vm.$emit('submitForm', noteText);

      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          noteableId: workItemId,
          body: noteText,
          discussionId: null,
        },
      });
    });

    it('tracks adding comment', async () => {
      await createComponent();
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findCommentForm().vm.$emit('submitForm', 'test');

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'add_work_item_comment', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_comment',
        property: 'type_Task',
      });
    });

    it('emits `replied` event and hides form after successful mutation', async () => {
      await createComponent({
        isEditing: true,
        signedIn: true,
        queryVariables: {
          id: mockWorkItemNotesResponse.data.workItem.id,
        },
      });

      findCommentForm().vm.$emit('submitForm', 'some text');
      await waitForPromises();

      expect(wrapper.emitted('replied')).toEqual([[]]);
    });

    it('clears a draft after successful mutation', async () => {
      await createComponent({
        isEditing: true,
        signedIn: true,
      });

      findCommentForm().vm.$emit('submitForm', 'some text');
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

      findCommentForm().vm.$emit('submitForm', 'updated desc');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('emits error when mutation fails', async () => {
      const error = 'eror';

      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockRejectedValue(new Error(error)),
      });

      findCommentForm().vm.$emit('submitForm', 'updated desc');

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

      findCommentForm().vm.$emit('submitForm', 'updated desc');

      await waitForPromises();

      expect(clearDraft).toHaveBeenCalledWith('gid://gitlab/WorkItem/1-comment');
    });
  });

  it('calls the global ID work item query when `fetchByIid` prop is false', async () => {
    createComponent({ fetchByIid: false });
    await waitForPromises();

    expect(workItemResponseHandler).toHaveBeenCalled();
    expect(workItemByIidResponseHandler).not.toHaveBeenCalled();
  });

  it('calls the IID work item query when when `fetchByIid` prop is true', async () => {
    await createComponent({ fetchByIid: true, isEditing: false });

    expect(workItemResponseHandler).not.toHaveBeenCalled();
    expect(workItemByIidResponseHandler).toHaveBeenCalled();
  });

  it('skips calling the handlers when missing the needed queryVariables', async () => {
    await createComponent({ queryVariables: {}, fetchByIid: false, isEditing: false });

    expect(workItemResponseHandler).not.toHaveBeenCalled();
  });
});
