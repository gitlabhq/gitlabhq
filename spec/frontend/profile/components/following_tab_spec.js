import { GlBadge, GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import FollowingTab from '~/profile/components/following_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FollowingTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(FollowingTab, {
      provide: {
        followees: 3,
      },
    });
  };

  it('renders `GlTab` and sets title', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).element.textContent).toContain(
      s__('UserProfile|Following'),
    );
  });

  it('renders `GlBadge`, sets size and content', () => {
    createComponent();

    expect(wrapper.findComponent(GlBadge).attributes('size')).toBe('sm');
    expect(wrapper.findComponent(GlBadge).element.textContent).toBe('3');
  });
});
