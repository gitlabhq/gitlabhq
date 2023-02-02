import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import FollowersTab from '~/profile/components/followers_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FollowersTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(FollowersTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Followers'));
  });
});
