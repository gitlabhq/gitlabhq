import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import BoardApp from '~/boards/components/board_app.vue';

describe('BoardApp', () => {
  let wrapper;
  let store;

  Vue.use(Vuex);

  const createStore = ({ mockGetters = {} } = {}) => {
    store = new Vuex.Store({
      state: {},
      actions: {
        performSearch: jest.fn(),
      },
      getters: {
        isSidebarOpen: () => true,
        ...mockGetters,
      },
    });
  };

  const createComponent = () => {
    wrapper = shallowMount(BoardApp, {
      store,
      provide: {
        initialBoardId: 'gid://gitlab/Board/1',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  it("should have 'is-compact' class when sidebar is open", () => {
    createStore();
    createComponent();

    expect(wrapper.classes()).toContain('is-compact');
  });

  it("should not have 'is-compact' class when sidebar is closed", () => {
    createStore({ mockGetters: { isSidebarOpen: () => false } });
    createComponent();

    expect(wrapper.classes()).not.toContain('is-compact');
  });
});
