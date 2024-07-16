import { GlEmptyState } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsExploreEmptyState from '~/groups/components/empty_states/groups_explore_empty_state.vue';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

let wrapper;

const createComponent = () => {
  wrapper = shallowMountExtended(GroupsExploreEmptyState);
};

afterEach(() => {
  window.gon = {};
});

describe('GroupsExploreEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: 'No public or internal groups',
      svgPath: 'empty-groups-md.svg',
    });
  });
});
