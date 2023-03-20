import { GlTab } from '@gitlab/ui';

import { s__ } from '~/locale';
import OverviewTab from '~/profile/components/overview_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';

describe('OverviewTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(OverviewTab);
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Overview'));
  });

  it('renders `ActivityCalendar` component', () => {
    createComponent();

    expect(wrapper.findComponent(ActivityCalendar).exists()).toBe(true);
  });
});
