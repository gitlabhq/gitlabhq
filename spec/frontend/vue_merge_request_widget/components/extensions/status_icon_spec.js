import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusIcon from '~/vue_merge_request_widget/components/extensions/status_icon.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(StatusIcon, {
    propsData,
  });
}

describe('MR widget extensions status icon', () => {
  it('renders loading icon', () => {
    factory({ name: 'test', isLoading: true, iconName: 'failed' });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders status icon', () => {
    factory({ name: 'test', isLoading: false, iconName: 'failed' });

    expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('status-failed');
  });

  it('sets aria-label for status icon', () => {
    factory({ name: 'test', isLoading: false, iconName: 'failed' });

    expect(wrapper.findComponent(GlIcon).props('ariaLabel')).toBe('Failed test');
  });
});
