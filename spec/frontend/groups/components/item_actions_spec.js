import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
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
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findEditGroupBtn = () => wrapper.find('[data-testid="edit-group-btn"]');
  const findEditGroupIcon = () => findEditGroupBtn().find(GlIcon);
  const findLeaveGroupBtn = () => wrapper.find('[data-testid="leave-group-btn"]');
  const findLeaveGroupIcon = () => findLeaveGroupBtn().find(GlIcon);

  describe('template', () => {
    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('controls');
    });

    it('renders "Edit group" button with correct attribute values', () => {
      const group = {
        ...mockParentGroupItem,
        canEdit: true,
      };

      createComponent({ group });

      expect(findEditGroupBtn().exists()).toBe(true);
      expect(findEditGroupBtn().classes()).toContain('no-expand');
      expect(findEditGroupBtn().attributes('href')).toBe(group.editPath);
      expect(findEditGroupBtn().attributes('aria-label')).toBe('Edit group');
      expect(findEditGroupBtn().attributes('data-original-title')).toBe('Edit group');
      expect(findEditGroupIcon().exists()).toBe(true);
      expect(findEditGroupIcon().props('name')).toBe('settings');
    });

    describe('`canLeave` is true', () => {
      const group = {
        ...mockParentGroupItem,
        canLeave: true,
      };

      beforeEach(() => {
        createComponent({ group });
      });

      it('renders "Leave this group" button with correct attribute values', () => {
        expect(findLeaveGroupBtn().exists()).toBe(true);
        expect(findLeaveGroupBtn().classes()).toContain('no-expand');
        expect(findLeaveGroupBtn().attributes('href')).toBe(group.leavePath);
        expect(findLeaveGroupBtn().attributes('aria-label')).toBe('Leave this group');
        expect(findLeaveGroupBtn().attributes('data-original-title')).toBe('Leave this group');
        expect(findLeaveGroupIcon().exists()).toBe(true);
        expect(findLeaveGroupIcon().props('name')).toBe('leave');
      });

      it('emits event on "Leave this group" button click', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        findLeaveGroupBtn().trigger('click');

        expect(eventHub.$emit).toHaveBeenCalledWith('showLeaveGroupModal', group, parentGroup);
      });
    });
  });
});
