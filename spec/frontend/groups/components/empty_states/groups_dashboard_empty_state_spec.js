import { GlEmptyState } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsDashboardEmptyState from '~/groups/components/empty_states/groups_dashboard_empty_state.vue';

let wrapper;

const defaultProvide = {
  groupsEmptyStateIllustration: '/assets/illustrations/empty-state/empty-groups-md.svg',
};

const createComponent = () => {
  wrapper = shallowMountExtended(GroupsDashboardEmptyState, {
    provide: defaultProvide,
  });
};

describe('GroupsDashboardEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: 'A group is a collection of several projects',
      description:
        "If you organize your projects under a group, it works like a folder. You can manage your group member's permissions and access to each project in the group.",
      svgPath: defaultProvide.groupsEmptyStateIllustration,
    });
  });
});
