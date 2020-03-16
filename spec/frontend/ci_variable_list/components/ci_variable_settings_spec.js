import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import CiVariableSettings from '~/ci_variable_list/components/ci_variable_settings.vue';
import createStore from '~/ci_variable_list/store';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci variable table', () => {
  let wrapper;
  let store;
  let isGroup;

  const createComponent = groupState => {
    store = createStore();
    store.state.isGroup = groupState;
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = shallowMount(CiVariableSettings, {
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches fetchEnvironments when mounted', () => {
    isGroup = false;
    createComponent(isGroup);
    expect(store.dispatch).toHaveBeenCalledWith('fetchEnvironments');
  });

  it('does not dispatch fetchenvironments when in group context', () => {
    isGroup = true;
    createComponent(isGroup);
    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
