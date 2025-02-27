import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import { items } from '~/vue_shared/components/nested_groups_projects_list/mock_data';

describe('NestedGroupsProjectsList', () => {
  let wrapper;

  const defaultPropsData = {
    items,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(NestedGroupsProjectsList, {
      propsData: defaultPropsData,
    });
  };

  it('renders list with `NestedGroupsProjectsListItem` component', () => {
    createComponent();

    const listItemWrappers = wrapper.findAllComponents(NestedGroupsProjectsListItem).wrappers;
    const expectedProps = listItemWrappers.map((listItemWrapper) => listItemWrapper.props());

    expect(expectedProps).toEqual(
      defaultPropsData.items.map((item) => ({
        item,
      })),
    );
  });
});
