import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerGoogleCloudOption from '~/ci/runner/components/runner_google_cloud_option.vue';
import RunnerPlatformsRadio from '~/ci/runner/components/runner_platforms_radio.vue';

describe('RunnerGoogleCloudOption', () => {
  let wrapper;

  const findFormRadio = () => wrapper.findComponent(RunnerPlatformsRadio);
  const findLabel = () => wrapper.find('label');

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerGoogleCloudOption, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  it('displays form radio', () => {
    createComponent();

    expect(findFormRadio().exists()).toBe(true);
  });

  it('displays form radio label', () => {
    createComponent();

    expect(findLabel().text()).toBe('Cloud');
  });

  it('emits input event', () => {
    createComponent();

    findFormRadio().vm.$emit('input', 'google_cloud');

    expect(wrapper.emitted()).toEqual({ input: [['google_cloud']] });
  });

  it('sets radio value when checked prop is passed', () => {
    createComponent({ checked: 'google_cloud' });

    expect(findFormRadio().attributes('value')).toBe('google_cloud');
  });
});
