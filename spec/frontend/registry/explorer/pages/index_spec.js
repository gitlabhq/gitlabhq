import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/pages/index.vue';

describe('List Page', () => {
  let wrapper;

  const findRouterView = () => wrapper.find({ ref: 'router-view' });

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
