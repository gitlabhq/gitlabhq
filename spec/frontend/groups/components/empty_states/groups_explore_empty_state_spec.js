import { GlEmptyState } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsExploreEmptyState from '~/groups/components/empty_states/groups_explore_empty_state.vue';

let wrapper;

const defaultProvide = {
  groupsEmptyStateIllustration: '/assets/illustrations/empty-state/empty-groups-md.svg',
};

const createComponent = () => {
  wrapper = shallowMountExtended(GroupsExploreEmptyState, {
    provide: defaultProvide,
  });
};

describe('GroupsExploreEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: 'No public groups',
      svgPath: defaultProvide.groupsEmptyStateIllustration,
    });
  });
});
