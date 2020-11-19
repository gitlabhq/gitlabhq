import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/terraform/components/empty_state.vue';

describe('EmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    image: '/image/path',
  };

  beforeEach(() => {
    wrapper = shallowMount(EmptyState, { propsData, stubs: { GlEmptyState, GlSprintf } });
    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render content', () => {
    expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    expect(wrapper.text()).toContain('Get started with Terraform');
  });
});
