import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatarLink } from '@gitlab/ui';
import mockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { updateDraft, clearDraft } from '~/lib/utils/autosave';
import EditedAt from '~/issues/show/components/edited.vue';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import WorkItemNoteAwardsList from '~/work_items/components/notes/work_item_note_awards_list.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import WorkItemCommentForm from '~/work_items/components/notes/work_item_comment_form.vue';
import updateWorkItemNoteMutation from '~/work_items/graphql/notes/update_work_item_note.mutation.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  mockAssignees,
  mockWorkItemCommentNote,
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
  workItemQueryResponse,
  mockWorkItemCommentNoteByContributor,
  mockWorkItemCommentByMaintainer,
} from 'jest/work_items/mock_data';
import { i18n, TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import { mockTracking } from 'helpers/tracking_helper';

Vue.use(VueApollo);
jest.mock('~/lib/utils/autosave');

describe('Work Item Note', () => {
  let wrapper;
  const updatedNoteText = '# Some title';
  const updatedNoteBody = '<h1 data-sourcepos="1:1-1:12" dir="auto">Some title</h1>';
  const mockWorkItemId = workItemQueryResponse.data.workItem.id;

  const mockWorkItemByDifferentUser = {
    data: {
      workItem: {
        ...workItemQueryResponse.data.workItem,
        author: {
          avatarUrl:
            'http://127.0.0.1:3000/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          id: 'gid://gitlab/User/2',
          name: 'User 1',
          username: 'user1',
          webUrl: 'http://127.0.0.1:3000/user1',
          __typename: 'UserCore',
        },
      },
    },
  };

  const successHandler = jest.fn().mockResolvedValue({
    data: {
      updateNote: {
        errors: [],
        note: {
          ...mockWorkItemCommentNote,
          body: updatedNoteText,
          bodyHtml: updatedNoteBody,
        },
      },
    },
  });

  const workItemResponseHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const workItemByAuthoredByDifferentUser = jest
    .fn()
    .mockResolvedValue(mockWorkItemByDifferentUser);

  const updateWorkItemMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const errorHandler = jest.fn().mockRejectedValue('Oops');

  const findAwardsList = () => wrapper.findComponent(WorkItemNoteAwardsList);
  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findNoteHeader = () => wrapper.findComponent(NoteHeader);
  const findNoteBody = () => wrapper.findComponent(NoteBody);
  const findNoteActions = () => wrapper.findComponent(NoteActions);
  const findCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findEditedAt = () => wrapper.findComponent(EditedAt);

  const createComponent = ({
    note = mockWorkItemCommentNote,
    isFirstNote = false,
    updateNoteMutationHandler = successHandler,
    workItemId = mockWorkItemId,
    updateWorkItemMutationHandler = updateWorkItemMutationSuccessHandler,
    assignees = mockAssignees,
    workItemByIidResponseHandler = workItemResponseHandler,
  } = {}) => {
    wrapper = shallowMount(WorkItemNote, {
      propsData: {
        fullPath: 'test-project-path',
        workItemId,
        workItemIid: '1',
        note,
        isFirstNote,
        workItemType: 'Task',
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
        assignees,
      },
      stubs: {
        TimelineEntryItem,
      },
      mocks: {
        $route: {},
      },
      apolloProvider: mockApollo([
        [workItemByIidQuery, workItemByIidResponseHandler],
        [updateWorkItemNoteMutation, updateNoteMutationHandler],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
      ]),
    });
  };

  describe('when editing', () => {
    beforeEach(() => {
      createComponent();

      findNoteActions().vm.$emit('startEditing');
      return nextTick();
    });

    it('should render a comment form', () => {
      expect(findCommentForm().exists()).toBe(true);
    });

    it('should not render note body', () => {
      expect(findNoteBody().exists()).toBe(false);
    });

    it('updates saved draft with current note text', () => {
      expect(updateDraft).toHaveBeenCalledWith(
        `${mockWorkItemCommentNote.id}-comment`,
        mockWorkItemCommentNote.body,
      );
    });

    it('passes correct autosave key prop to comment form component', () => {
      expect(findCommentForm().props('autosaveKey')).toBe(`${mockWorkItemCommentNote.id}-comment`);
    });

    it('should hide a form and show wrapper when user cancels editing', async () => {
      findCommentForm().vm.$emit('cancelEditing');
      await nextTick();

      expect(findCommentForm().exists()).toBe(false);
      expect(findNoteBody().exists()).toBe(true);
    });

    it('should show the awards list when in edit mode', async () => {
      createComponent({ note: mockWorkItemCommentNote });
      findNoteActions().vm.$emit('startEditing');
      await nextTick();
      expect(findAwardsList().exists()).toBe(true);
    });
  });

  describe('when submitting a form to edit a note', () => {
    it('calls update mutation with correct variables', async () => {
      createComponent();
      findNoteActions().vm.$emit('startEditing');
      await nextTick();

      findCommentForm().vm.$emit('submitForm', { commentText: updatedNoteText });

      expect(successHandler).toHaveBeenCalledWith({
        input: {
          id: mockWorkItemCommentNote.id,
          body: updatedNoteText,
        },
      });
    });

    it('hides the form after successful mutation', async () => {
      createComponent();
      findNoteActions().vm.$emit('startEditing');
      await nextTick();

      findCommentForm().vm.$emit('submitForm', { commentText: updatedNoteText });
      await waitForPromises();

      expect(findCommentForm().exists()).toBe(false);
      expect(clearDraft).toHaveBeenCalledWith(`${mockWorkItemCommentNote.id}-comment`);
    });

    describe('when mutation fails', () => {
      beforeEach(async () => {
        createComponent({ updateNoteMutationHandler: errorHandler });
        findNoteActions().vm.$emit('startEditing');
        await nextTick();

        findCommentForm().vm.$emit('submitForm', { commentText: updatedNoteText });
        await waitForPromises();
      });

      it('opens the form again', () => {
        expect(findCommentForm().exists()).toBe(true);
      });

      it('updates the saved draft with the latest comment text', () => {
        expect(updateDraft).toHaveBeenCalledWith(
          `${mockWorkItemCommentNote.id}-comment`,
          updatedNoteText,
        );
      });

      it('emits an error', () => {
        expect(wrapper.emitted('error')).toHaveLength(1);
      });
    });
  });

  describe('when not editing', () => {
    it('should not render a comment form', () => {
      createComponent();
      expect(findCommentForm().exists()).toBe(false);
    });

    it('should render note wrapper', () => {
      createComponent();
      expect(findNoteBody().exists()).toBe(true);
    });

    it('renders no "edited at" information by default', () => {
      createComponent();
      expect(findEditedAt().exists()).toBe(false);
    });

    it('renders "edited at" information if the note was edited', () => {
      createComponent({
        note: {
          ...mockWorkItemCommentNote,
          lastEditedAt: '2023-02-12T07:47:40Z',
          lastEditedBy: { ...mockWorkItemCommentNote.author, webPath: 'test-path' },
        },
      });

      expect(findEditedAt().props()).toMatchObject({
        updatedAt: '2023-02-12T07:47:40Z',
        updatedByName: 'Administrator',
        updatedByPath: 'test-path',
      });
    });

    describe('main comment', () => {
      beforeEach(async () => {
        createComponent({ isFirstNote: true });
        await waitForPromises();
      });

      it('should have the note header, actions and body', () => {
        expect(findTimelineEntryItem().exists()).toBe(true);
        expect(findNoteHeader().exists()).toBe(true);
        expect(findNoteBody().exists()).toBe(true);
        expect(findNoteActions().exists()).toBe(true);
      });

      it('should have the reply button props', () => {
        expect(findNoteActions().props('showReply')).toBe(true);
      });

      it('should have the project name', () => {
        expect(findNoteActions().props('projectName')).toBe('Project name');
      });

      it('should pass the noteUrl to the note header and should be a work items url', () => {
        expect(findNoteHeader().props('noteUrl')).toContain('work_items');
      });
    });

    describe('comment threads', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should show avatar link with popover support', () => {
        const avatarLink = findTimelineEntryItem().findComponent(GlAvatarLink);
        const { author } = mockWorkItemCommentNote;

        expect(avatarLink.exists()).toBe(true);
        expect(avatarLink.classes()).toContain('js-user-link');
        expect(avatarLink.attributes()).toMatchObject({
          href: author.webUrl,
          'data-user-id': '1',
          'data-username': `${author.username}`,
        });
      });

      it('should have the note header, actions and body', () => {
        expect(findTimelineEntryItem().exists()).toBe(true);
        expect(findNoteHeader().exists()).toBe(true);
        expect(findNoteBody().exists()).toBe(true);
        expect(findNoteActions().exists()).toBe(true);
      });

      it('should not have the reply button props', () => {
        expect(findNoteActions().props('showReply')).toBe(false);
      });
    });

    describe('assign/unassign to commenting user', () => {
      it('calls a mutation with correct variables', async () => {
        createComponent({ assignees: mockAssignees });
        await waitForPromises();
        findNoteActions().vm.$emit('assignUser');

        await waitForPromises();

        expect(updateWorkItemMutationSuccessHandler).toHaveBeenCalledWith({
          input: {
            id: mockWorkItemId,
            assigneesWidget: {
              assigneeIds: [mockAssignees[1].id],
            },
          },
        });
      });

      it('emits an error and resets assignees if mutation was rejected', async () => {
        createComponent({
          updateWorkItemMutationHandler: errorHandler,
          assignees: [mockAssignees[0]],
        });

        await waitForPromises();

        expect(findNoteActions().props('isAuthorAnAssignee')).toEqual(true);

        findNoteActions().vm.$emit('assignUser');

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
        expect(findNoteActions().props('isAuthorAnAssignee')).toEqual(true);
      });

      it('tracks the event', async () => {
        createComponent();
        await waitForPromises();
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findNoteActions().vm.$emit('assignUser');

        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'unassigned_user', {
          category: TRACKING_CATEGORY_SHOW,
          label: 'work_item_note_actions',
          property: 'type_Task',
        });
      });
    });

    describe('report abuse props', () => {
      it.each`
        currentUserId | canReportAbuse | sameAsAuthor
        ${1}          | ${false}       | ${'same as'}
        ${4}          | ${true}        | ${'not same as'}
      `(
        'should be $canReportAbuse when the author is $sameAsAuthor as the author of the note',
        ({ currentUserId, canReportAbuse }) => {
          window.gon = {
            current_user_id: currentUserId,
          };
          createComponent();

          expect(findNoteActions().props('canReportAbuse')).toBe(canReportAbuse);
        },
      );
    });

    describe('internal note', () => {
      it('does not have the internal note class set by default', () => {
        createComponent();
        expect(findTimelineEntryItem().classes()).not.toContain('internal-note');
      });

      it('timeline entry item and note header has the class for internal notes', () => {
        createComponent({
          note: {
            ...mockWorkItemCommentNote,
            internal: true,
          },
        });
        expect(findTimelineEntryItem().classes()).toContain('internal-note');
        expect(findNoteHeader().props('isInternalNote')).toBe(true);
      });
    });

    it('confidential information on note', async () => {
      createComponent();
      await findNoteActions().vm.$emit('startEditing');
      const { confidential } = workItemByIidResponseFactory().data.workspace.workItem;
      expect(findCommentForm().props('isWorkItemConfidential')).toBe(confidential);
    });

    describe('author and user role badges', () => {
      describe('author badge props', () => {
        it.each`
          isWorkItemAuthor | sameAsCurrentUser | workItemByIidResponseHandler
          ${true}          | ${'same as'}      | ${workItemResponseHandler}
          ${false}         | ${'not same as'}  | ${workItemByAuthoredByDifferentUser}
        `(
          'should pass correct isWorkItemAuthor `$isWorkItemAuthor` to note actions when author is $sameAsCurrentUser as current note',
          async ({ isWorkItemAuthor, workItemByIidResponseHandler }) => {
            createComponent({ workItemByIidResponseHandler });
            await waitForPromises();

            expect(findNoteActions().props('isWorkItemAuthor')).toBe(isWorkItemAuthor);
          },
        );
      });

      describe('Max access level badge', () => {
        it('should pass the max access badge props', async () => {
          createComponent({ note: mockWorkItemCommentByMaintainer });
          await waitForPromises();

          expect(findNoteActions().props('maxAccessLevelOfAuthor')).toBe(
            mockWorkItemCommentByMaintainer.maxAccessLevelOfAuthor,
          );
        });
      });

      describe('Contributor badge', () => {
        it('should pass the contributor props', async () => {
          createComponent({ note: mockWorkItemCommentNoteByContributor });
          await waitForPromises();

          expect(findNoteActions().props('isAuthorContributor')).toBe(
            mockWorkItemCommentNoteByContributor.authorIsContributor,
          );
        });
      });
    });

    it('passes note props to awards list', () => {
      createComponent({ note: mockWorkItemCommentNote });

      expect(findAwardsList().props('note')).toBe(mockWorkItemCommentNote);
      expect(findAwardsList().props('workItemIid')).toBe('1');
    });

    it('passes external author to note header', () => {
      const externalAuthor = 'user@example.com';

      createComponent({
        note: {
          ...mockWorkItemCommentNote,
          externalAuthor,
        },
      });

      expect(findNoteHeader().props('emailParticipant')).toBe(externalAuthor);
    });
  });

  it('calls the work item query', () => {
    createComponent();

    expect(workItemResponseHandler).toHaveBeenCalled();
  });

  describe('when note has no author', () => {
    beforeEach(() => {
      createComponent({
        note: {
          ...mockWorkItemCommentNote,
          author: null,
        },
      });
    });

    it('should pass correct author prop to note header', () => {
      expect(findNoteHeader().props('author')).toEqual({});
    });

    it('should not allow assigning to comment author', () => {
      expect(findNoteActions().props('showAssignUnassign')).toBe(false);
    });
  });
});
