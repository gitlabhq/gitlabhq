import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import { MAX_CHILDREN_COUNT } from '~/groups/constants';
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
    wrapper = createComponent();

    expect(findLink().exists()).toBe(false);
  });

  it('renders text of count of excess children when children count of group is over limit', () => {
    const childrenCount = MAX_CHILDREN_COUNT + 1;
    wrapper = createComponent({
      parentGroup: {
        ...mockParentGroupItem,
        childrenCount,
      },
    });

    expect(findLink().text()).toBe(`${childrenCount} more items`);
  });

  it('renders group items', () => {
    wrapper = createComponent();

    expect(wrapper.findAllComponents(GroupItem)).toHaveLength(7);
  });
});
