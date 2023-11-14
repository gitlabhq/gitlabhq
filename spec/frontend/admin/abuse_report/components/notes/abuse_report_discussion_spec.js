import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import AbuseReportDiscussion from '~/admin/abuse_report/components/notes/abuse_report_discussion.vue';
import AbuseReportNote from '~/admin/abuse_report/components/notes/abuse_report_note.vue';

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
      });
    });

    it('should not show timeline entry item component', () => {
      expect(findTimelineEntryItem().exists()).toBe(false);
    });

    it('should not show the the toggle replies widget wrapper when no replies', () => {
      expect(findToggleRepliesWidget().exists()).toBe(false);
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
  });
});
