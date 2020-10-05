import { shallowMount } from '@vue/test-utils';
import Default from '~/feature_flags/components/strategies/default.vue';

describe('~/feature_flags/components/strategies/default.vue', () => {
  it('should emit an empty parameter object on mount', () => {
    const wrapper = shallowMount(Default);

    expect(wrapper.emitted('change')).toEqual([[{ parameters: {} }]]);
  });
});
