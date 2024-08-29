import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import WorkItemNoteReplying from '~/work_items/components/notes/work_item_note_replying.vue';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import toggleWorkItemNoteResolveDiscussion from '~/work_items/graphql/notes/toggle_work_item_note_resolve_discussion.mutation.graphql';
import {
  mockWorkItemCommentNote,
  mockToggleResolveDiscussionResponse,
  mockWorkItemNotesResponseWithComments,
} from 'jest/work_items/mock_data';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';

const mockWorkItemNotesWidgetResponseWithComments =
  mockWorkItemNotesResponseWithComments().data.workspace.workItem.widgets.find(
    (widget) => widget.type === WIDGET_TYPE_NOTES,
  );

describe('Work Item Discussion', () => {
  Vue.use(VueApollo);

  let wrapper;
  const mockWorkItemId = 'gid://gitlab/WorkItem/625';

  const findToggleRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findAllThreads = () => wrapper.findAllComponents(WorkItemNote);
  const findThreadAtIndex = (index) => findAllThreads().at(index);
  const findWorkItemAddNote = () => wrapper.findComponent(WorkItemAddNote);
  const findWorkItemNoteReplying = () => wrapper.findComponent(WorkItemNoteReplying);

  const toggleWorkItemResolveDiscussionHandler = jest
    .fn()
    .mockResolvedValue(mockToggleResolveDiscussionResponse);

  const createComponent = ({
    discussion = [mockWorkItemCommentNote],
    workItemId = mockWorkItemId,
    workItemType = 'Task',
    isExpandedOnLoad = true,
  } = {}) => {
    wrapper = shallowMount(WorkItemDiscussion, {
      apolloProvider: createMockApollo([
        [toggleWorkItemNoteResolveDiscussion, toggleWorkItemResolveDiscussionHandler],
      ]),
      propsData: {
        fullPath: 'gitlab-org',
        discussion,
        workItemId,
        workItemIid: '1',
        workItemType,
        markdownPreviewPath: '/group/project/preview_markdown?target_type=WorkItem',
        autocompleteDataSources: {},
        isExpandedOnLoad,
      },
    });
  };

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not show the the toggle replies widget wrapper when no replies', () => {
      expect(findToggleRepliesWidget().exists()).toBe(false);
    });

    it('should not show the comment form by default', () => {
      expect(findWorkItemAddNote().exists()).toBe(false);
    });
  });

  describe('When the main comments has threads', () => {
    beforeEach(() => {
      createComponent({
        discussion: mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes,
      });
    });

    it('should show the toggle replies widget', () => {
      expect(findToggleRepliesWidget().exists()).toBe(true);
    });

    it('the number of threads should be equal to the response length', () => {
      expect(findAllThreads()).toHaveLength(
        mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes.length,
      );
    });

    it('should collapse when we click on toggle replies widget', async () => {
      findToggleRepliesWidget().vm.$emit('toggle');
      await nextTick();
      expect(findAllThreads()).toHaveLength(1);
    });

    it('should autofocus when we click expand replies', async () => {
      const mainComment = findThreadAtIndex(0);

      mainComment.vm.$emit('startReplying');
      await nextTick();
      expect(findWorkItemAddNote().exists()).toBe(true);
      expect(findWorkItemAddNote().props('autofocus')).toBe(true);
    });

    it('should send the correct props is when the main comment is internal', async () => {
      const mainComment = findThreadAtIndex(0);

      mainComment.vm.$emit('startReplying');
      await nextTick();
      expect(findWorkItemAddNote().props('isInternalThread')).toBe(
        mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes[0].internal,
      );
    });
  });

  describe('When replying to any comment', () => {
    beforeEach(async () => {
      createComponent({
        discussion: mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes,
      });
      const mainComment = findThreadAtIndex(0);

      mainComment.vm.$emit('startReplying');
      await nextTick();
      await findWorkItemAddNote().vm.$emit('replying', 'reply text');
    });

    it('should show optimistic behavior when replying', () => {
      expect(findAllThreads()).toHaveLength(2);
      expect(findWorkItemNoteReplying().exists()).toBe(true);
    });

    it('should be expanded when the reply is successful', async () => {
      findWorkItemAddNote().vm.$emit('replied');
      await nextTick();
      expect(findToggleRepliesWidget().exists()).toBe(true);
      expect(findToggleRepliesWidget().props('collapsed')).toBe(false);
    });

    it('should pass `is-internal-note` props to make sure the correct background is set', () => {
      expect(findWorkItemNoteReplying().exists()).toBe(true);
      expect(findWorkItemNoteReplying().props('isInternalNote')).toBe(
        mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes[0].internal,
      );
    });
  });

  it('emits `deleteNote` event with correct parameter when child note component emits `deleteNote` event', () => {
    createComponent();
    findThreadAtIndex(0).vm.$emit('deleteNote');

    expect(wrapper.emitted('deleteNote')).toEqual([[mockWorkItemCommentNote]]);
  });

  it('emits `error` event when child note emits an `error`', () => {
    const mockErrorText = 'Houston, we have a problem';

    createComponent();
    findThreadAtIndex(0).vm.$emit('error', mockErrorText);

    expect(wrapper.emitted('error')).toEqual([[mockErrorText]]);
  });

  describe('Resolve discussion', () => {
    beforeEach(() => {
      window.gon.current_user_id = 'gid://gitlab/User/1';
      window.gon.current_user_fullname = 'Administrator';
    });
    const resolvedDiscussionList =
      mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes.slice();
    resolvedDiscussionList.forEach((note) => {
      return {
        ...note,
        discussion: {
          id: note.discussion.id,
          resolved: true,
          resolvable: true,
          resolvedBy: {
            id: 'gid://gitlab/User/1',
            name: 'Administrator',
            __typename: 'UserCore',
          },
          __typename: 'Discussion',
        },
      };
    });

    it('Resolved discussion is not expanded on default', () => {
      createComponent({
        discussion: resolvedDiscussionList,
        isExpandedOnLoad: false,
      });

      expect(findToggleRepliesWidget().props('collapsed')).toBe(true);
    });

    it('should pass `isDiscussionResolvable` prop as true when user has resolveNote permission', () => {
      createComponent({
        discussion: resolvedDiscussionList,
        isExpandedOnLoad: false,
      });

      expect(findThreadAtIndex(0).props('isDiscussionResolvable')).toBe(true);
    });

    it('should pass `isDiscussionResolvable` prop as false when user does not have resolveNote permission', () => {
      const resolvedDiscussionListWithoutPermissions = resolvedDiscussionList.map((note) => {
        return {
          ...note,
          userPermissions: {
            adminNote: true,
            awardEmoji: true,
            readNote: true,
            createNote: true,
            resolveNote: false,
            repositionNote: true,
            __typename: 'NotePermissions',
          },
        };
      });

      createComponent({
        discussion: resolvedDiscussionListWithoutPermissions,
        isExpandedOnLoad: false,
      });

      expect(findThreadAtIndex(0).props('isDiscussionResolvable')).toBe(false);
    });

    it('toggles resolved status when toggle icon is clicked from note header', async () => {
      createComponent({
        discussion:
          mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes.slice(),
        isExpandedOnLoad: true,
      });

      const mainComment = findThreadAtIndex(0);

      expect(findToggleRepliesWidget().props('collapsed')).toBe(false);

      mainComment.vm.$emit('resolve');

      expect(toggleWorkItemResolveDiscussionHandler).toHaveBeenCalled();

      await nextTick();

      expect(findToggleRepliesWidget().props('collapsed')).toBe(false);
    });
  });
});
