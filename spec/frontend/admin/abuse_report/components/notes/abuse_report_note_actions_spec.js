import { shallowMount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import AbuseReportNoteActions from '~/admin/abuse_report/components/notes/abuse_report_note_actions.vue';

describe('Abuse Report Note Actions', () => {
  let wrapper;
  const mockShowReplyButton = true;

  const findReplyButton = () => wrapper.findComponent(ReplyButton);

  const createComponent = ({ showReplyButton = mockShowReplyButton } = {}) => {
    wrapper = shallowMount(AbuseReportNoteActions, {
      propsData: {
        showReplyButton,
      },
    });
  };

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should show reply button', () => {
      expect(findReplyButton().exists()).toBe(true);
    });

    it('should emit `startReplying`', () => {
      findReplyButton().vm.$emit('startReplying');

      expect(wrapper.emitted('startReplying')).toHaveLength(1);
    });
  });

  describe('When `showReplyButton` is false', () => {
    beforeEach(() => {
      createComponent({
        showReplyButton: false,
      });
    });

    it('should not show reply button', () => {
      expect(findReplyButton().exists()).toBe(false);
    });
  });
});
