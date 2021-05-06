import { mount, createLocalVue } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import {
  mapVuexModuleActions,
  mapVuexModuleGetters,
  mapVuexModuleState,
  REQUIRE_STRING_ERROR_MESSAGE,
} from '~/lib/utils/vuex_module_mappers';

const TEST_MODULE_NAME = 'testModuleName';

const localVue = createLocalVue();
localVue.use(Vuex);

// setup test component and store ----------------------------------------------
//
// These are used to indirectly test `vuex_module_mappers`.
const TestComponent = Vue.extend({
  props: {
    vuexModule: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapVuexModuleState((vm) => vm.vuexModule, { name: 'name', value: 'count' }),
    ...mapVuexModuleGetters((vm) => vm.vuexModule, ['hasValue', 'hasName']),
    stateJson() {
      return JSON.stringify({
        name: this.name,
        value: this.value,
      });
    },
    gettersJson() {
      return JSON.stringify({
        hasValue: this.hasValue,
        hasName: this.hasName,
      });
    },
  },
  methods: {
    ...mapVuexModuleActions((vm) => vm.vuexModule, ['increment']),
  },
  template: `
<div>
  <pre data-testid="state">{{ stateJson }}</pre>
  <pre data-testid="getters">{{ gettersJson }}</pre>
</div>`,
});

const createTestStore = () => {
  return new Vuex.Store({
    modules: {
      [TEST_MODULE_NAME]: {
        namespaced: true,
        state: {
          name: 'Lorem',
          count: 0,
        },
        mutations: {
          INCREMENT: (state, amount) => {
            state.count += amount;
          },
        },
        actions: {
          increment({ commit }, amount) {
            commit('INCREMENT', amount);
          },
        },
        getters: {
          hasValue: (state) => state.count > 0,
          hasName: (state) => Boolean(state.name.length),
        },
      },
    },
  });
};

describe('~/lib/utils/vuex_module_mappers', () => {
  let store;
  let wrapper;

  const getJsonInTemplate = (testId) =>
    JSON.parse(wrapper.find(`[data-testid="${testId}"]`).text());
  const getMappedState = () => getJsonInTemplate('state');
  const getMappedGetters = () => getJsonInTemplate('getters');

  beforeEach(() => {
    store = createTestStore();

    wrapper = mount(TestComponent, {
      propsData: {
        vuexModule: TEST_MODULE_NAME,
      },
      store,
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('from module defined by prop', () => {
    it('maps state', () => {
      expect(getMappedState()).toEqual({
        name: store.state[TEST_MODULE_NAME].name,
        value: store.state[TEST_MODULE_NAME].count,
      });
    });

    it('maps getters', () => {
      expect(getMappedGetters()).toEqual({
        hasName: true,
        hasValue: false,
      });
    });

    it('maps action', () => {
      jest.spyOn(store, 'dispatch');

      expect(store.dispatch).not.toHaveBeenCalled();

      wrapper.vm.increment(10);

      expect(store.dispatch).toHaveBeenCalledWith(`${TEST_MODULE_NAME}/increment`, 10);
    });
  });

  describe('with non-string object value', () => {
    it('throws helpful error', () => {
      expect(() => mapVuexModuleActions((vm) => vm.bogus, { foo: () => {} })).toThrowError(
        REQUIRE_STRING_ERROR_MESSAGE,
      );
    });
  });
});
