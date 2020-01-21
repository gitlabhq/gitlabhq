import { shallowMount } from '@vue/test-utils';
import DurationBadge from '~/jobs/components/log/duration_badge.vue';

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

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders provided duration', () => {
    expect(wrapper.text()).toBe(data.duration);
  });
});
