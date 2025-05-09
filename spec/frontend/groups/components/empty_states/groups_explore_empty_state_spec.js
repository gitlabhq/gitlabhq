import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsExploreEmptyState from '~/groups/components/empty_states/groups_explore_empty_state.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

let wrapper;

const createComponent = () => {
  wrapper = shallowMountExtended(GroupsExploreEmptyState);
};

describe('GroupsExploreEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(ResourceListsEmptyState).props()).toMatchObject({
      title: 'No public or internal groups',
      svgPath: 'empty-groups-md.svg',
      search: '',
    });
  });
});
