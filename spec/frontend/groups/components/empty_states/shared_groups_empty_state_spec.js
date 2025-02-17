import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SharedGroupsEmptyState from '~/groups/components/empty_states/shared_groups_empty_state.vue';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

let wrapper;

const createComponent = () => {
  wrapper = mountExtended(SharedGroupsEmptyState);
};

describe('SharedGroupsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: 'This group has not been invited to any other groups.',
      svgPath: 'empty-groups-md.svg',
    });
    expect(wrapper.text()).toContain(
      'Other groups this group has been invited to will appear here.',
    );
  });
});
