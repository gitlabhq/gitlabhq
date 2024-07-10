import { GlEmptyState } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupsDashboardEmptyState from '~/groups/components/empty_states/groups_dashboard_empty_state.vue';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

let wrapper;

const createComponent = () => {
  wrapper = shallowMountExtended(GroupsDashboardEmptyState);
};

describe('GroupsDashboardEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: 'A group is a collection of several projects',
      description:
        "If you organize your projects under a group, it works like a folder. You can manage your group member's permissions and access to each project in the group.",
      svgPath: 'empty-groups-md.svg',
    });
  });
});
