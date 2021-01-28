import { shallowMount } from '@vue/test-utils';
import ItemActions from '~/groups/components/item_actions.vue';
import eventHub from '~/groups/event_hub';
import { mockParentGroupItem, mockChildren } from '../mock_data';

describe('ItemActions', () => {
  let wrapper;
  const parentGroup = mockChildren[0];

  const defaultProps = {
    group: mockParentGroupItem,
    parentGroup,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ItemActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findEditGroupBtn = () => wrapper.find('[data-testid="edit-group-btn"]');
  const findLeaveGroupBtn = () => wrapper.find('[data-testid="leave-group-btn"]');

  describe('template', () => {
    let group;

    beforeEach(() => {
      group = {
        ...mockParentGroupItem,
        canEdit: true,
        canLeave: true,
      };
      createComponent({ group });
    });

    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('controls');
    });

    it('renders "Edit group" button with correct attribute values', () => {
      const button = findEditGroupBtn();
      expect(button.exists()).toBe(true);
      expect(button.props('icon')).toBe('pencil');
      expect(button.attributes('aria-label')).toBe('Edit group');
    });

    it('renders "Leave this group" button with correct attribute values', () => {
      const button = findLeaveGroupBtn();
      expect(button.exists()).toBe(true);
      expect(button.props('icon')).toBe('leave');
      expect(button.attributes('aria-label')).toBe('Leave this group');
    });

    it('emits `showLeaveGroupModal` event in the event hub', () => {
      jest.spyOn(eventHub, '$emit');
      findLeaveGroupBtn().vm.$emit('click', { stopPropagation: () => {} });

      expect(eventHub.$emit).toHaveBeenCalledWith('showLeaveGroupModal', group, parentGroup);
    });
  });

  it('emits `showLeaveGroupModal` event with the correct prefix if `action` prop is passed', () => {
    const group = {
      ...mockParentGroupItem,
      canEdit: true,
      canLeave: true,
    };
    createComponent({
      group,
      action: 'test',
    });
    jest.spyOn(eventHub, '$emit');
    findLeaveGroupBtn().vm.$emit('click', { stopPropagation: () => {} });

    expect(eventHub.$emit).toHaveBeenCalledWith('testshowLeaveGroupModal', group, parentGroup);
  });

  it('does not render leave button if group can not be left', () => {
    createComponent({
      group: {
        ...mockParentGroupItem,
        canLeave: false,
      },
    });

    expect(findLeaveGroupBtn().exists()).toBe(false);
  });

  it('does not render edit button if group can not be edited', () => {
    createComponent({
      group: {
        ...mockParentGroupItem,
        canEdit: false,
      },
    });

    expect(findEditGroupBtn().exists()).toBe(false);
  });
});
