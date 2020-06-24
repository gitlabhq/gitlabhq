import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VariablesSection from '~/monitoring/components/variables_section.vue';
import DropdownField from '~/monitoring/components/variables/dropdown_field.vue';
import TextField from '~/monitoring/components/variables/text_field.vue';
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
    label4: mockTemplatingDataResponses.metricLabelValues.simple,
  };

  const createShallowWrapper = () => {
    wrapper = shallowMount(VariablesSection, {
      store,
    });
  };

  const findTextInputs = () => wrapper.findAll(TextField);
  const findCustomInputs = () => wrapper.findAll(DropdownField);

  beforeEach(() => {
    store = createStore();

    store.state.monitoringDashboard.showEmptyState = false;
  });

  it('does not show the variables section', () => {
    createShallowWrapper();
    const allInputs = findTextInputs().length + findCustomInputs().length;

    expect(allInputs).toBe(0);
  });

  describe('when variables are set', () => {
    beforeEach(() => {
      createShallowWrapper();
      store.commit(`monitoringDashboard/${types.SET_VARIABLES}`, sampleVariables);
      return wrapper.vm.$nextTick;
    });

    it('shows the variables section', () => {
      const allInputs = findTextInputs().length + findCustomInputs().length;

      expect(allInputs).toBe(Object.keys(sampleVariables).length);
    });

    it('shows the right custom variable inputs', () => {
      const customInputs = findCustomInputs();

      expect(customInputs.at(0).props('name')).toBe('label3');
      expect(customInputs.at(1).props('name')).toBe('label4');
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
      const firstInput = findTextInputs().at(0);

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
      const firstInput = findCustomInputs().at(0);

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
      const firstInput = findTextInputs().at(0);

      firstInput.vm.$emit('onUpdate', 'label1', 'Simple text');

      expect(updateVariablesAndFetchData).not.toHaveBeenCalled();
      expect(mergeUrlParams).not.toHaveBeenCalled();
      expect(updateHistory).not.toHaveBeenCalled();
    });
  });
});
