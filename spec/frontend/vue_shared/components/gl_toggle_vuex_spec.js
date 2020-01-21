import Vuex from 'vuex';
import { GlToggle } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import GlToggleVuex from '~/vue_shared/components/gl_toggle_vuex.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GlToggleVuex component', () => {
  let wrapper;
  let store;

  const findButton = () => wrapper.find('button');

  const createWrapper = (props = {}) => {
    wrapper = mount(GlToggleVuex, {
      localVue,
      store,
      propsData: {
        stateProperty: 'toggleState',
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store({
      state: {
        toggleState: false,
      },
      actions: {
        setToggleState: ({ commit }, { key, value }) => commit('setToggleState', { key, value }),
      },
      mutations: {
        setToggleState: (state, { key, value }) => {
          state[key] = value;
        },
      },
    });
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders gl-toggle', () => {
    expect(wrapper.find(GlToggle).exists()).toBe(true);
  });

  it('properly computes default value for setAction', () => {
    expect(wrapper.props('setAction')).toBe('setToggleState');
  });

  describe('without a store module', () => {
    it('calls action with new value when value changes', () => {
      jest.spyOn(store, 'dispatch');

      findButton().trigger('click');
      expect(store.dispatch).toHaveBeenCalledWith('setToggleState', {
        key: 'toggleState',
        value: true,
      });
    });

    it('updates store property when value changes', () => {
      findButton().trigger('click');
      expect(store.state.toggleState).toBe(true);
    });
  });

  describe('with a store module', () => {
    beforeEach(() => {
      store = new Vuex.Store({
        modules: {
          someModule: {
            namespaced: true,
            state: {
              toggleState: false,
            },
            actions: {
              setToggleState: ({ commit }, { key, value }) =>
                commit('setToggleState', { key, value }),
            },
            mutations: {
              setToggleState: (state, { key, value }) => {
                state[key] = value;
              },
            },
          },
        },
      });

      createWrapper({
        storeModule: 'someModule',
      });
    });

    it('calls action with new value when value changes', () => {
      jest.spyOn(store, 'dispatch');

      findButton().trigger('click');
      expect(store.dispatch).toHaveBeenCalledWith('someModule/setToggleState', {
        key: 'toggleState',
        value: true,
      });
    });

    it('updates store property when value changes', () => {
      findButton().trigger('click');
      expect(store.state.someModule.toggleState).toBe(true);
    });
  });
});
