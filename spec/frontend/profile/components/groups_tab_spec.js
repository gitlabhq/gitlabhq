import { GlTab } from '@gitlab/ui';

import GroupsTab from '~/profile/components/groups_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupsTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(GroupsTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe('Groups');
  });
});
