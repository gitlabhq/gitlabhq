import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import WorkItemNoteReplying from '~/work_items/components/notes/work_item_note_replying.vue';
import WorkItemCommentForm from '~/work_items/components/work_item_comment_form.vue';
import {
  mockWorkItemCommentNote,
  mockWorkItemNotesResponseWithComments,
} from 'jest/work_items/mock_data';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';

const mockWorkItemNotesWidgetResponseWithComments = mockWorkItemNotesResponseWithComments.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

describe('Work Item Discussion', () => {
  let wrapper;
  const mockWorkItemId = 'gid://gitlab/WorkItem/625';

  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findToggleRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findAllThreads = () => wrapper.findAllComponents(WorkItemNote);
  const findThreadAtIndex = (index) => findAllThreads().at(index);
  const findWorkItemCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findWorkItemNoteReplying = () => wrapper.findComponent(WorkItemNoteReplying);

  const createComponent = ({
    discussion = [mockWorkItemCommentNote],
    workItemId = mockWorkItemId,
    queryVariables = { id: workItemId },
    fetchByIid = false,
    fullPath = 'gitlab-org',
    workItemType = 'Task',
  } = {}) => {
    wrapper = shallowMount(WorkItemDiscussion, {
      propsData: {
        discussion,
        workItemId,
        queryVariables,
        fetchByIid,
        fullPath,
        workItemType,
      },
    });
  };

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Should be wrapped inside the timeline entry item', () => {
      expect(findTimelineEntryItem().exists()).toBe(true);
    });

    it('should have the author avatar of the work item note', () => {
      expect(findAvatarLink().exists()).toBe(true);
      expect(findAvatarLink().attributes('href')).toBe(mockWorkItemCommentNote.author.webUrl);

      expect(findAvatar().exists()).toBe(true);
      expect(findAvatar().props('src')).toBe(mockWorkItemCommentNote.author.avatarUrl);
      expect(findAvatar().props('entityName')).toBe(mockWorkItemCommentNote.author.username);
    });

    it('should not show the the toggle replies widget wrapper when no replies', () => {
      expect(findToggleRepliesWidget().exists()).toBe(false);
    });

    it('should not show the comment form by default', () => {
      expect(findWorkItemCommentForm().exists()).toBe(false);
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

    it('the number of threads should be equal to the response length', async () => {
      findToggleRepliesWidget().vm.$emit('toggle');
      await nextTick();
      expect(findAllThreads()).toHaveLength(
        mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[0].notes.nodes.length,
      );
    });

    it('should autofocus when we click expand replies', async () => {
      const mainComment = findThreadAtIndex(0);

      mainComment.vm.$emit('startReplying');
      await nextTick();
      expect(findWorkItemCommentForm().exists()).toBe(true);
      expect(findWorkItemCommentForm().props('autofocus')).toBe(true);
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
      await findWorkItemCommentForm().vm.$emit('replying', 'reply text');
    });

    it('should show optimistic behavior when replying', async () => {
      expect(findAllThreads()).toHaveLength(2);
      expect(findWorkItemNoteReplying().exists()).toBe(true);
    });

    it('should be expanded when the reply is successful', async () => {
      findWorkItemCommentForm().vm.$emit('replied');
      await nextTick();
      expect(findToggleRepliesWidget().exists()).toBe(true);
      expect(findToggleRepliesWidget().props('collapsed')).toBe(false);
    });
  });

  it('emits `deleteNote` event with correct parameter when child note component emits `deleteNote` event', () => {
    createComponent();
    findThreadAtIndex(0).vm.$emit('deleteNote');

    expect(wrapper.emitted('deleteNote')).toEqual([[mockWorkItemCommentNote]]);
  });
});
