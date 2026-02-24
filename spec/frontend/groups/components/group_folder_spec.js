import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import { mockGroups, mockParentGroupItem } from '../mock_data';

describe('GroupFolder component', () => {
  let wrapper;

  Vue.component('GroupItem', GroupItem);

  const findLink = () => wrapper.find('a');

  const createComponent = ({ groups = mockGroups, parentGroup = mockParentGroupItem } = {}) =>
    shallowMount(GroupFolder, {
      propsData: {
        groups,
        parentGroup,
      },
    });

  it('does not render more children stats link when children count of group is under limit', () => {
    wrapper = createComponent({
      parentGroup: {
        ...mockParentGroupItem,
        children: mockGroups,
        childrenCount: mockGroups.length,
      },
    });

    expect(findLink().exists()).toBe(false);
  });

  it('renders text of count of excess children when children count of group is over limit', () => {
    const childrenCount = mockGroups.length + 1;
    wrapper = createComponent({
      parentGroup: {
        ...mockParentGroupItem,
        childrenCount,
        children: mockGroups,
      },
    });

    expect(findLink().text()).toBe('One more item');
  });

  it('renders group items', () => {
    wrapper = createComponent();

    expect(wrapper.findAllComponents(GroupItem)).toHaveLength(7);
  });

  describe('when childrenCount is undefined', () => {
    describe.each([mockGroups.slice(1), [], undefined, null])('when children is %s', (value) => {
      it('does not render more children stats link', () => {
        wrapper = createComponent({
          parentGroup: { ...mockParentGroupItem, children: value, childrenCount: undefined },
        });

        expect(findLink().exists()).toBe(false);
      });
    });
  });

  describe('when children is undefined', () => {
    describe('when childrenCount is zero', () => {
      it('does not render more children stats link', () => {
        wrapper = createComponent({
          parentGroup: { ...mockParentGroupItem, children: undefined, childrenCount: 0 },
        });

        expect(findLink().exists()).toBe(false);
      });
    });

    describe('when childrenCount is greater than zero', () => {
      it('renders more children stats link', () => {
        wrapper = createComponent({
          parentGroup: { ...mockParentGroupItem, children: undefined, childrenCount: 2 },
        });

        expect(findLink().exists()).toBe(true);
        expect(findLink().text()).toBe('2 more items');
      });
    });
  });
});
