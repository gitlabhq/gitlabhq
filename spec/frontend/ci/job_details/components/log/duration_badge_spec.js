import { shallowMount } from '@vue/test-utils';
import DurationBadge from '~/ci/job_details/components/log/duration_badge.vue';

describe('Job Log Duration Badge', () => {
  let wrapper;

  const data = {
    duration: '00:30:01',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DurationBadge, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent(data);
  });

  it('renders provided duration', () => {
    expect(wrapper.text()).toBe(data.duration);
  });
});
