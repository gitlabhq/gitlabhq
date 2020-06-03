import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/pages/index.vue';
import { createStore } from '~/registry/explorer/stores/';

describe('List Page', () => {
  let wrapper;
  let store;

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
    store = createStore();
    mountComponent();
  });

  it('has a router view', () => {
    expect(findRouterView().exists()).toBe(true);
  });
});
