import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import CiVariableTable from '~/ci_variable_list/components/ci_variable_table.vue';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ci variable table', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = mount(CiVariableTable, {
      attachTo: document.body,
      localVue,
      store,
    });
  };

  const findRevealButton = () => wrapper.find({ ref: 'secret-value-reveal-button' });
  const findEditButton = () => wrapper.find({ ref: 'edit-ci-variable' });
  const findEmptyVariablesPlaceholder = () => wrapper.find({ ref: 'empty-variables' });

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches fetchVariables when mounted', () => {
    expect(store.dispatch).toHaveBeenCalledWith('fetchVariables');
  });

  describe('Renders correct data', () => {
    it('displays empty message when variables are not present', () => {
      expect(findEmptyVariablesPlaceholder().exists()).toBe(true);
    });

    it('displays correct amount of variables present and no empty message', () => {
      store.state.variables = mockData.mockVariables;

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.findAll('.js-ci-variable-row').length).toBe(1);
        expect(findEmptyVariablesPlaceholder().exists()).toBe(false);
      });
    });
  });

  describe('Table click actions', () => {
    beforeEach(() => {
      store.state.variables = mockData.mockVariables;
    });

    it('reveals secret values when button is clicked', () => {
      findRevealButton().trigger('click');
      expect(store.dispatch).toHaveBeenCalledWith('toggleValues', false);
    });

    it('dispatches editVariable with correct variable to edit', () => {
      findEditButton().trigger('click');
      expect(store.dispatch).toHaveBeenCalledWith('editVariable', mockData.mockVariables[0]);
    });
  });
});
