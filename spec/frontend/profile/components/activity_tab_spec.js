import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import ActivityTab from '~/profile/components/activity_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ActivityTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ActivityTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Activity'));
  });
});
