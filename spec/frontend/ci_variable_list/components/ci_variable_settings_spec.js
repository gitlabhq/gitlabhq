import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import CiVariableSettings from '~/ci_variable_list/components/ci_variable_settings.vue';
import ciVariableModal from '~/ci_variable_list/components/ci_variable_modal.vue';
import ciVariableTable from '~/ci_variable_list/components/ci_variable_table.vue';
import {
  ADD_VARIABLE_ACTION,
  EDIT_VARIABLE_ACTION,
  projectString,
} from '~/ci_variable_list/constants';
import { mapEnvironmentNames } from '~/ci_variable_list/utils';

import { mockEnvs, mockVariablesWithScopes, newVariable } from '../mocks';

describe('Ci variable table', () => {
  let wrapper;

  const defaultProps = {
    areScopedVariablesAvailable: true,
    environments: mapEnvironmentNames(mockEnvs),
    hideEnvironmentScope: false,
    isLoading: false,
    variables: mockVariablesWithScopes(projectString),
  };

  const findCiVariableTable = () => wrapper.findComponent(ciVariableTable);
  const findCiVariableModal = () => wrapper.findComponent(ciVariableModal);

  const createComponent = () => {
    wrapper = shallowMount(CiVariableSettings, {
      propsData: {
        ...defaultProps,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('props passing', () => {
    it('passes props down correctly to the ci table', () => {
      expect(findCiVariableTable().props()).toEqual({
        isLoading: defaultProps.isLoading,
        variables: defaultProps.variables,
      });
    });

    it('passes props down correctly to the ci modal', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable');
      await nextTick();

      expect(findCiVariableModal().props()).toEqual({
        areScopedVariablesAvailable: defaultProps.areScopedVariablesAvailable,
        environments: defaultProps.environments,
        hideEnvironmentScope: defaultProps.hideEnvironmentScope,
        variables: defaultProps.variables,
        mode: ADD_VARIABLE_ACTION,
        selectedVariable: {},
      });
    });
  });

  describe('modal mode', () => {
    it('passes down ADD mode when receiving an empty variable', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable');
      await nextTick();

      expect(findCiVariableModal().props('mode')).toBe(ADD_VARIABLE_ACTION);
    });

    it('passes down EDIT mode when receiving a variable', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable', newVariable);
      await nextTick();

      expect(findCiVariableModal().props('mode')).toBe(EDIT_VARIABLE_ACTION);
    });
  });

  describe('variable modal', () => {
    it('is hidden by default', () => {
      expect(findCiVariableModal().exists()).toBe(false);
    });

    it('shows modal when adding a new variable', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable');
      await nextTick();

      expect(findCiVariableModal().exists()).toBe(true);
    });

    it('shows modal when updating a variable', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable', newVariable);
      await nextTick();

      expect(findCiVariableModal().exists()).toBe(true);
    });

    it('hides modal when receiving the event from the modal', async () => {
      findCiVariableTable().vm.$emit('set-selected-variable');
      await nextTick();

      findCiVariableModal().vm.$emit('hideModal');
      await nextTick();

      expect(findCiVariableModal().exists()).toBe(false);
    });
  });

  describe('variable events', () => {
    it.each`
      eventName
      ${'add-variable'}
      ${'update-variable'}
      ${'delete-variable'}
    `('bubbles up the $eventName event', async ({ eventName }) => {
      findCiVariableTable().vm.$emit('set-selected-variable');
      await nextTick();

      findCiVariableModal().vm.$emit(eventName, newVariable);
      await nextTick();

      expect(wrapper.emitted(eventName)).toEqual([[newVariable]]);
    });
  });
});
