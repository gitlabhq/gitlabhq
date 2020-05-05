import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/pages/index.vue';
import store from '~/registry/explorer/stores/';

describe('List Page', () => {
  let wrapper;

  const findRouterView = () => wrapper.find({ ref: 'router-view' });

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      store,
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
