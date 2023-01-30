import { shallowMount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import WorkItemNoteActions from '~/work_items/components/notes/work_item_note_actions.vue';

describe('Work Item Note Actions', () => {
  let wrapper;

  const findReplyButton = () => wrapper.findComponent(ReplyButton);

  const createComponent = ({ showReply = true } = {}) => {
    wrapper = shallowMount(WorkItemNoteActions, {
      propsData: {
        showReply,
      },
    });
  };

  describe('Default', () => {
    it('Should show the reply button by default', () => {
      createComponent();
      expect(findReplyButton().exists()).toBe(true);
    });
  });

  describe('When the reply button needs to be hidden', () => {
    it('Should show the reply button by default', () => {
      createComponent({ showReply: false });
      expect(findReplyButton().exists()).toBe(false);
    });
  });
});
