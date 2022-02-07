import Vue from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiVariableTable from '~/ci_variable_list/components/ci_variable_table.vue';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';

Vue.use(Vuex);

describe('Ci variable table', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = mountExtended(CiVariableTable, {
      attachTo: document.body,
      store,
    });
  };

  const findRevealButton = () => wrapper.findByText('Reveal values');
  const findEditButton = () => wrapper.findByLabelText('Edit');
  const findEmptyVariablesPlaceholder = () => wrapper.findByText('There are no variables yet.');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches fetchVariables when mounted', () => {
    expect(store.dispatch).toHaveBeenCalledWith('fetchVariables');
  });

  describe('When table is empty', () => {
    beforeEach(() => {
      store.state.variables = [];
    });

    it('displays empty message', () => {
      expect(findEmptyVariablesPlaceholder().exists()).toBe(true);
    });

    it('hides the reveal button', () => {
      expect(findRevealButton().exists()).toBe(false);
    });
  });

  describe('When table has variables', () => {
    beforeEach(() => {
      store.state.variables = mockData.mockVariables;
    });

    it('does not display the empty message', () => {
      expect(findEmptyVariablesPlaceholder().exists()).toBe(false);
    });

    it('displays the reveal button', () => {
      expect(findRevealButton().exists()).toBe(true);
    });

    it('displays the correct amount of variables', async () => {
      expect(wrapper.findAll('.js-ci-variable-row')).toHaveLength(1);
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
