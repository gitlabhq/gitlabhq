import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import OverviewTab from '~/profile/components/overview_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('OverviewTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(OverviewTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Overview'));
  });
});
