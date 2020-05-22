import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VariablesSection from '~/monitoring/components/variables_section.vue';
import CustomVariable from '~/monitoring/components/variables/custom_variable.vue';
import TextVariable from '~/monitoring/components/variables/text_variable.vue';
import { updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { createStore } from '~/monitoring/stores';
import { convertVariablesForURL } from '~/monitoring/utils';
import * as types from '~/monitoring/stores/mutation_types';
import { mockTemplatingDataResponses } from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  updateHistory: jest.fn(),
  mergeUrlParams: jest.fn(),
}));

describe('Metrics dashboard/variables section component', () => {
  let store;
  let wrapper;
  const sampleVariables = {
    label1: mockTemplatingDataResponses.simpleText.simpleText,
    label2: mockTemplatingDataResponses.advText.advText,
    label3: mockTemplatingDataResponses.simpleCustom.simpleCustom,
  };

  const createShallowWrapper = () => {
    wrapper = shallowMount(VariablesSection, {
      store,
    });
  };

  const findTextInput = () => wrapper.findAll(TextVariable);
  const findCustomInput = () => wrapper.findAll(CustomVariable);

  beforeEach(() => {
    store = createStore();

    store.state.monitoringDashboard.showEmptyState = false;
  });

  it('does not show the variables section', () => {
    createShallowWrapper();
    const allInputs = findTextInput().length + findCustomInput().length;

    expect(allInputs).toBe(0);
  });

  it('shows the variables section', () => {
    createShallowWrapper();
    store.commit(`monitoringDashboard/${types.SET_VARIABLES}`, sampleVariables);

    return wrapper.vm.$nextTick(() => {
      const allInputs = findTextInput().length + findCustomInput().length;

      expect(allInputs).toBe(Object.keys(sampleVariables).length);
    });
  });

  describe('when changing the variable inputs', () => {
    const updateVariablesAndFetchData = jest.fn();

    beforeEach(() => {
      store = new Vuex.Store({
        modules: {
          monitoringDashboard: {
            namespaced: true,
            state: {
              showEmptyState: false,
              variables: sampleVariables,
            },
            actions: {
              updateVariablesAndFetchData,
            },
          },
        },
      });

      createShallowWrapper();
    });

    it('merges the url params and refreshes the dashboard when a text-based variables inputs are updated', () => {
      const firstInput = findTextInput().at(0);

      firstInput.vm.$emit('onUpdate', 'label1', 'test');

      return wrapper.vm.$nextTick(() => {
        expect(updateVariablesAndFetchData).toHaveBeenCalled();
        expect(mergeUrlParams).toHaveBeenCalledWith(
          convertVariablesForURL(sampleVariables),
          window.location.href,
        );
        expect(updateHistory).toHaveBeenCalled();
      });
    });

    it('merges the url params and refreshes the dashboard when a custom-based variables inputs are updated', () => {
      const firstInput = findCustomInput().at(0);

      firstInput.vm.$emit('onUpdate', 'label1', 'test');

      return wrapper.vm.$nextTick(() => {
        expect(updateVariablesAndFetchData).toHaveBeenCalled();
        expect(mergeUrlParams).toHaveBeenCalledWith(
          convertVariablesForURL(sampleVariables),
          window.location.href,
        );
        expect(updateHistory).toHaveBeenCalled();
      });
    });

    it('does not merge the url params and refreshes the dashboard if the value entered is not different that is what currently stored', () => {
      const firstInput = findTextInput().at(0);

      firstInput.vm.$emit('onUpdate', 'label1', 'Simple text');

      expect(updateVariablesAndFetchData).not.toHaveBeenCalled();
      expect(mergeUrlParams).not.toHaveBeenCalled();
      expect(updateHistory).not.toHaveBeenCalled();
    });
  });
});
