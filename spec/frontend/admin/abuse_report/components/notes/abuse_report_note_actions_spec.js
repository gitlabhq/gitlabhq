import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective } from 'helpers/vue_mock_directive';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import AbuseReportNoteActions from '~/admin/abuse_report/components/notes/abuse_report_note_actions.vue';

describe('Abuse Report Note Actions', () => {
  let wrapper;

  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ showReplyButton = true, showEditButton = true } = {}) => {
    wrapper = shallowMount(AbuseReportNoteActions, {
      propsData: {
        showReplyButton,
        showEditButton,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
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

    it('should emit `startReplying` when reply button is clicked', () => {
      findReplyButton().vm.$emit('startReplying');

      expect(wrapper.emitted('startReplying')).toHaveLength(1);
    });

    it('should show edit button', () => {
      expect(findEditButton().exists()).toBe(true);
      expect(findEditButton().attributes()).toMatchObject({
        icon: 'pencil',
        title: 'Edit comment',
        'aria-label': 'Edit comment',
      });
    });

    it('should emit `startEditing` when edit button is clicked', () => {
      findEditButton().vm.$emit('click');

      expect(wrapper.emitted('startEditing')).toHaveLength(1);
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

  describe('When `showEditButton` is false', () => {
    beforeEach(() => {
      createComponent({
        showEditButton: false,
      });
    });

    it('should not show edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });
});
