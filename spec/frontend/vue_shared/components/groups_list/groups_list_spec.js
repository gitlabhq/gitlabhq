import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { groups } from './mock_data';

describe('GroupsList', () => {
  let wrapper;

  const defaultPropsData = {
    items: groups,
    listItemClass: 'gl-px-5',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(GroupsList, {
      propsData: defaultPropsData,
    });
  };

  it('renders list with `GroupsListItem` component', () => {
    createComponent();

    const groupsListItemWrappers = wrapper.findAllComponents(GroupsListItem).wrappers;
    const expectedProps = groupsListItemWrappers.map((groupsListItemWrapper) =>
      groupsListItemWrapper.props(),
    );

    expect(expectedProps).toEqual(
      defaultPropsData.items.map((group) => ({
        group,
        showGroupIcon: false,
        listItemClass: defaultPropsData.listItemClass,
        timestampType: TIMESTAMP_TYPE_CREATED_AT,
      })),
    );
  });

  describe('when `GroupsListItem` emits `refetch` event', () => {
    beforeEach(() => {
      createComponent();

      wrapper.findComponent(GroupsListItem).vm.$emit('refetch');
    });

    it('emits `refetch` event', () => {
      expect(wrapper.emitted('refetch')).toEqual([[]]);
    });
  });
});
