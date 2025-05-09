import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardGroupsEmptyState from '~/groups/components/empty_states/dashboard_groups_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

let wrapper;

const createComponent = () => {
  wrapper = shallowMountExtended(DashboardGroupsEmptyState);
};

describe('DashboardGroupsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(ResourceListsEmptyState).props()).toMatchObject({
      title: 'A group is a collection of several projects',
      description:
        "If you organize your projects under a group, it works like a folder. You can manage your group member's permissions and access to each project in the group.",
      svgPath: 'empty-groups-md.svg',
      search: '',
    });
  });
});
