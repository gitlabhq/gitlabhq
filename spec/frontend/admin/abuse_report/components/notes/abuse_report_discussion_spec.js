import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import AbuseReportDiscussion from '~/admin/abuse_report/components/notes/abuse_report_discussion.vue';
import AbuseReportNote from '~/admin/abuse_report/components/notes/abuse_report_note.vue';
import AbuseReportAddNote from '~/admin/abuse_report/components/notes/abuse_report_add_note.vue';

import {
  mockAbuseReport,
  mockDiscussionWithNoReplies,
  mockDiscussionWithReplies,
} from '../../mock_data';

describe('Abuse Report Discussion', () => {
  let wrapper;
  const mockAbuseReportId = mockAbuseReport.report.globalId;

  const findAbuseReportNote = () => wrapper.findComponent(AbuseReportNote);
  const findAbuseReportNotes = () => wrapper.findAllComponents(AbuseReportNote);
  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findToggleRepliesWidget = () => wrapper.findComponent(ToggleRepliesWidget);
  const findAbuseReportAddNote = () => wrapper.findComponent(AbuseReportAddNote);

  const createComponent = ({
    discussion = mockDiscussionWithNoReplies,
    abuseReportId = mockAbuseReportId,
  } = {}) => {
    wrapper = shallowMount(AbuseReportDiscussion, {
      propsData: {
        discussion,
        abuseReportId,
      },
    });
  };

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should show the abuse report note', () => {
      expect(findAbuseReportNote().exists()).toBe(true);

      expect(findAbuseReportNote().props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        note: mockDiscussionWithNoReplies[0],
        showReplyButton: true,
      });
    });

    it('should not show timeline entry item component', () => {
      expect(findTimelineEntryItem().exists()).toBe(false);
    });

    it('should not show the toggle replies widget wrapper when there are no replies', () => {
      expect(findToggleRepliesWidget().exists()).toBe(false);
    });

    it('should not show the comment form there are no replies', () => {
      expect(findAbuseReportAddNote().exists()).toBe(false);
    });
  });

  describe('When the main comments has replies', () => {
    beforeEach(() => {
      createComponent({
        discussion: mockDiscussionWithReplies,
      });
    });

    it('should show the toggle replies widget', () => {
      expect(findToggleRepliesWidget().exists()).toBe(true);
    });

    it('the number of replies should be equal to the response length', () => {
      expect(findAbuseReportNotes()).toHaveLength(3);
    });

    it('should collapse when we click on toggle replies widget', async () => {
      findToggleRepliesWidget().vm.$emit('toggle');
      await nextTick();
      expect(findAbuseReportNotes()).toHaveLength(1);
    });

    it('should show the comment form', () => {
      expect(findAbuseReportAddNote().exists()).toBe(true);

      expect(findAbuseReportAddNote().props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        discussionId: mockDiscussionWithReplies[0].discussion.id,
        isNewDiscussion: false,
      });
    });

    it('should show the reply button only for the main comment', () => {
      expect(findAbuseReportNotes().at(0).props('showReplyButton')).toBe(true);

      expect(findAbuseReportNotes().at(1).props('showReplyButton')).toBe(false);
      expect(findAbuseReportNotes().at(2).props('showReplyButton')).toBe(false);
    });
  });

  describe('Replying to a comment when it has no replies', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should show comment form when `startReplying` is emitted', async () => {
      expect(findAbuseReportAddNote().exists()).toBe(false);

      findAbuseReportNote().vm.$emit('startReplying');
      await nextTick();

      expect(findAbuseReportAddNote().exists()).toBe(true);
      expect(findAbuseReportAddNote().props('showCommentForm')).toBe(true);
    });

    it('should hide the comment form when `cancelEditing` is emitted', async () => {
      findAbuseReportNote().vm.$emit('startReplying');
      await nextTick();

      findAbuseReportAddNote().vm.$emit('cancelEditing');
      await nextTick();

      expect(findAbuseReportAddNote().exists()).toBe(false);
    });
  });

  describe('Replying to a comment with replies', () => {
    beforeEach(() => {
      createComponent({
        discussion: mockDiscussionWithReplies,
      });
    });

    it('should show reply textarea, but not comment form', () => {
      expect(findAbuseReportAddNote().exists()).toBe(true);
      expect(findAbuseReportAddNote().props('showCommentForm')).toBe(false);
    });

    it('should show comment form when reply button on main comment is clicked', async () => {
      findAbuseReportNotes().at(0).vm.$emit('startReplying');
      await nextTick();

      expect(findAbuseReportAddNote().props('showCommentForm')).toBe(true);
    });
  });
});
