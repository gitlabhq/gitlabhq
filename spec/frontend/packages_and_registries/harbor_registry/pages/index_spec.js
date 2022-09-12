import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/harbor_registry/pages/index.vue';

describe('List Page', () => {
  let wrapper;

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      stubs: {
        RouterView: true,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('has a router view', () => {
    expect(findRouterView().exists()).toBe(true);
  });
});
