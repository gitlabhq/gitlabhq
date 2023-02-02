import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import FollowingTab from '~/profile/components/following_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FollowingTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(FollowingTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Following'));
  });
});
