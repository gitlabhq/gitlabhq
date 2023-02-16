import { shallowMount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import WorkItemNoteActions from '~/work_items/components/notes/work_item_note_actions.vue';

describe('Work Item Note Actions', () => {
  let wrapper;

  const findReplyButton = () => wrapper.findComponent(ReplyButton);
  const findEditButton = () => wrapper.find('[data-testid="edit-work-item-note"]');

  const createComponent = ({ showReply = true, showEdit = true } = {}) => {
    wrapper = shallowMount(WorkItemNoteActions, {
      propsData: {
        showReply,
        showEdit,
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

  it('shows edit button when `showEdit` prop is true', () => {
    createComponent();

    expect(findEditButton().exists()).toBe(true);
  });

  it('does not show edit button when `showEdit` prop is false', () => {
    createComponent({ showEdit: false });

    expect(findEditButton().exists()).toBe(false);
  });

  it('emits `startEditing` event when edit button is clicked', () => {
    createComponent();
    findEditButton().vm.$emit('click');

    expect(wrapper.emitted('startEditing')).toEqual([[]]);
  });
});
