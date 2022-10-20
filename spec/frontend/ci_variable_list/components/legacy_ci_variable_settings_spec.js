import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import LegacyCiVariableSettings from '~/ci_variable_list/components/legacy_ci_variable_settings.vue';
import createStore from '~/ci_variable_list/store';

Vue.use(Vuex);

describe('Ci variable table', () => {
  let wrapper;
  let store;
  let isProject;

  const createComponent = (projectState) => {
    store = createStore();
    store.state.isProject = projectState;
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = shallowMount(LegacyCiVariableSettings, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches fetchEnvironments when mounted', () => {
    isProject = true;
    createComponent(isProject);
    expect(store.dispatch).toHaveBeenCalledWith('fetchEnvironments');
  });

  it('does not dispatch fetchenvironments when in group context', () => {
    isProject = false;
    createComponent(isProject);
    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
