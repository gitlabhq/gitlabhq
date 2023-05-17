import { GlBadge, GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import FollowersTab from '~/profile/components/followers_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FollowersTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(FollowersTab, {
      provide: {
        followers: 2,
      },
    });
  };

  it('renders `GlTab` and sets title', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).element.textContent).toContain(
      s__('UserProfile|Followers'),
    );
  });

  it('renders `GlBadge`, sets size and content', () => {
    createComponent();

    expect(wrapper.findComponent(GlBadge).attributes('size')).toBe('sm');
    expect(wrapper.findComponent(GlBadge).element.textContent).toBe('2');
  });
});
