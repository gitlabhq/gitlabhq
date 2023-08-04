import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { groups } from './mock_data';

describe('GroupsList', () => {
  let wrapper;

  const defaultPropsData = {
    groups,
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
      defaultPropsData.groups.map((group) => ({
        group,
        showGroupIcon: false,
      })),
    );
  });
});
