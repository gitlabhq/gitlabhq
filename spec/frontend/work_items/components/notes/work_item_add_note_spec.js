import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import { clearDraft } from '~/lib/utils/autosave';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import WorkItemCommentLocked from '~/work_items/components/notes/work_item_comment_locked.vue';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import createNoteMutation from '~/work_items/graphql/notes/create_work_item_note.mutation.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';
import {
  createWorkItemNoteResponse,
  workItemByIidResponseFactory,
  workItemQueryResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

jest.mock('~/lib/utils/url_utility', () => {
  const actual = jest.requireActual('~/lib/utils/url_utility');
  return {
    ...actual,
    visitUrl: jest.fn(),
  };
});

const workItemId = workItemQueryResponse.data.workItem.id;

describe('Work item add note', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(createWorkItemNoteResponse());
  let workItemResponseHandler;

  const findCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findReplyPlaceholder = () => wrapper.findComponent(DiscussionReplyPlaceholder);
  const findSuccessAlert = () => wrapper.findByTestId('success-alert');
  const findWorkItemLockedComponent = () => wrapper.findComponent(WorkItemCommentLocked);
  const findResolveDiscussionButton = () => wrapper.findComponent(ResolveDiscussionButton);

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canCreateNote = true,
    emailParticipantsWidgetPresent = true,
    workItemIid = '1',
    signedIn = true,
    isEditing = true,
    isInternalThread = false,
    isNewDiscussion = false,
    isDiscussionResolved = false,
    isDiscussionResolvable = false,
    isResolving = false,
    isWorkItemConfidential = false,
    parentId = null,
  } = {}) => {
    const workItemResponse = workItemByIidResponseFactory({
      canCreateNote,
      emailParticipantsWidgetPresent,
    });
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);

    if (signedIn) {
      window.gon.current_user_id = '1';
      window.gon.current_user_avatar_url = 'avatar.png';
    }

    wrapper = shallowMountExtended(WorkItemAddNote, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemResponseHandler],
        [createNoteMutation, mutationHandler],
      ]),
      propsData: {
        fullPath: 'test-project-path',
        workItemId: workItemResponse.data.workspace.workItem.id,
        workItemIid,
        workItemType: 'Task',
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
        isInternalThread,
        isNewDiscussion,
        isDiscussionResolved,
        isDiscussionResolvable,
        isResolving,
        isWorkItemConfidential,
        parentId,
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
        await createComponent({ isEditing: true, signedIn: true });

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
          mutationHandler: jest
            .fn()
            .mockResolvedValue(createWorkItemNoteResponse({ errors: [error] })),
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
          mutationHandler: jest.fn().mockResolvedValue(
            createWorkItemNoteResponse({
              errors: ['Commands only Removed assignee @foobar.', 'Command names ["unassign"]'],
            }),
          ),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: 'updated desc',
          isNoteInternal: isInternalComment,
        });
        await waitForPromises();

        expect(clearDraft).toHaveBeenCalledWith('gid://gitlab/WorkItem/1-comment');
      });

      it('renders success alert on successful quick action', async () => {
        await createComponent({
          isEditing: true,
          mutationHandler: jest
            .fn()
            .mockResolvedValue(createWorkItemNoteResponse({ messages: ['Added ~"Label" label.'] })),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: '/label ~Label',
          isNoteInternal: isInternalComment,
        });
        await waitForPromises();

        expect(findSuccessAlert().text()).toBe('Added ~"Label" label.');
        expect(findSuccessAlert().props('variant')).toBe('info');
      });

      it('renders error alert on unsuccessful quick action', async () => {
        await createComponent({
          isEditing: true,
          mutationHandler: jest
            .fn()
            .mockResolvedValue(
              createWorkItemNoteResponse({ errorMessages: ['Failed to apply commands.'] }),
            ),
        });

        findCommentForm().vm.$emit('submitForm', {
          commentText: '/label doesnotexist',
          isNoteInternal: isInternalComment,
        });
        await waitForPromises();

        expect(findErrorAlert().text()).toBe('Failed to apply commands.');
        expect(findErrorAlert().props('variant')).toBe('danger');
      });

      it('refetches widgets when work item type is updated', async () => {
        await createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockResolvedValue(
            createWorkItemNoteResponse({
              errors: ['Commands only Type changed successfully.', 'Command names ["type"]'],
            }),
          ),
        });

        expect(workItemResponseHandler).toHaveBeenCalled();
      });

      it('emits error to parent when the comment form emits error', async () => {
        await createComponent({ isEditing: true, signedIn: true });
        const error = 'error';

        findCommentForm().vm.$emit('error', error);

        expect(wrapper.emitted('error')).toEqual([[error]]);
      });

      it('sends confidential prop to work item comment form', async () => {
        await createComponent({ isWorkItemConfidential: true });

        expect(findCommentForm().props('isWorkItemConfidential')).toBe(true);
      });
    });

    describe('when the work item type is changed to incident', () => {
      it.each`
        command                   | shouldPerformReload
        ${'/promote_to_incident'} | ${true}
        ${'/type Incident'}       | ${true}
        ${'/type incident'}       | ${true}
        ${'/promote_to Incident'} | ${true}
        ${'/promote_to incident'} | ${true}
        ${'/promote_to Epic'}     | ${false}
        ${'/type Issue'}          | ${false}
        ${'/type Task'}           | ${false}
        ${'No quick action'}      | ${false}
      `(
        'calls visitUrl $shouldPerformReload when note was added with command: $command',
        async ({ command, shouldPerformReload }) => {
          await createComponent({
            isEditing: true,
            mutationHandler: jest.fn().mockResolvedValue(
              createWorkItemNoteResponse({
                messages: ['Message does not matter because its localized'],
              }),
            ),
          });

          findCommentForm().vm.$emit('submitForm', {
            commentText: command,
          });

          await waitForPromises();

          if (shouldPerformReload) {
            expect(visitUrl).toHaveBeenCalled();
          } else {
            expect(visitUrl).not.toHaveBeenCalled();
          }
        },
      );
    });
  });

  it('calls the work item query', async () => {
    await createComponent();

    expect(workItemResponseHandler).toHaveBeenCalled();
  });

  it('skips calling the work item query when missing workItemIid', async () => {
    await createComponent({ workItemIid: '', isEditing: false });

    expect(workItemResponseHandler).not.toHaveBeenCalled();
  });

  it('wrapper adds `internal-note` class when internal thread', async () => {
    await createComponent({ isInternalThread: true });

    expect(wrapper.attributes('class')).toContain('internal-note');
  });

  describe('when work item `createNote` permission is false', () => {
    it('cannot add comment', async () => {
      await createComponent({ isEditing: false, canCreateNote: false });

      expect(findWorkItemLockedComponent().exists()).toBe(true);
      expect(findCommentForm().exists()).toBe(false);
    });
  });

  describe('email participants', () => {
    it('sets `hasEmailParticipantsWidget` prop to `true` for comment form by default', async () => {
      await createComponent();

      expect(findCommentForm().props('hasEmailParticipantsWidget')).toBe(true);
    });

    describe('when email participants widget is not available', () => {
      it('sets `hasEmailParticipantsWidget` prop to `false` for comment form', async () => {
        await createComponent({ emailParticipantsWidgetPresent: false });

        expect(findCommentForm().props('hasEmailParticipantsWidget')).toBe(false);
      });
    });
  });

  describe('Resolve Discussion button', () => {
    it('renders resolve discussion button when discussion is resolvable', async () => {
      await createComponent({ isDiscussionResolvable: true, isEditing: false });

      expect(findResolveDiscussionButton().exists()).toBe(true);
    });

    it('does not render resolve discussion button when discussion is not resolvable', async () => {
      await createComponent({ isDiscussionResolvable: false, isEditing: false });

      expect(findResolveDiscussionButton().exists()).toBe(false);
    });

    it('does not render resolve discussion button when it is a new discussion', async () => {
      await createComponent({
        isDiscussionResolvable: false,
        isEditing: false,
        isNewDiscussion: true,
      });

      expect(findResolveDiscussionButton().exists()).toBe(false);
    });

    it('emits `resolve` event when resolve discussion button is clicked', async () => {
      await createComponent({ isDiscussionResolvable: true, isEditing: false });

      findResolveDiscussionButton().vm.$emit('onClick');

      expect(wrapper.emitted('resolve')).toHaveLength(1);
    });

    it('passes correct props to resolve discussion button', async () => {
      await createComponent({
        isDiscussionResolvable: true,
        isDiscussionResolved: false,
        isResolving: true,
        isEditing: false,
      });

      expect(findResolveDiscussionButton().props()).toMatchObject({
        isResolving: true,
        buttonTitle: 'Resolve thread',
      });
    });
  });

  it('passes the `parentId` prop down to the `WorkItemCommentForm` component', async () => {
    await createComponent({ parentId: 'example-id' });

    expect(findCommentForm().props('parentId')).toBe('example-id');
  });
});
