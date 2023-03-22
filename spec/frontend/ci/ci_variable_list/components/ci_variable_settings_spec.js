import { shallowMount } from '@vue/test-utils';
import CiVariableSettings from '~/ci/ci_variable_list/components/ci_variable_settings.vue';
import ciVariableModal from '~/ci/ci_variable_list/components/ci_variable_modal.vue';
import ciVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import {
  ADD_VARIABLE_ACTION,
  EDIT_VARIABLE_ACTION,
  projectString,
} from '~/ci/ci_variable_list/constants';
import { mapEnvironmentNames } from '~/ci/ci_variable_list/utils';

import { mockEnvs, mockVariablesWithScopes, newVariable } from '../mocks';

describe('Ci variable table', () => {
  let wrapper;

  const defaultProps = {
    areEnvironmentsLoading: false,
    areScopedVariablesAvailable: true,
    entity: 'project',
    environments: mapEnvironmentNames(mockEnvs),
    hideEnvironmentScope: false,
    isLoading: false,
    maxVariableLimit: 5,
    pageInfo: { after: '' },
    variables: mockVariablesWithScopes(projectString),
  };

  const findCiVariableTable = () => wrapper.findComponent(ciVariableTable);
  const findCiVariableModal = () => wrapper.findComponent(ciVariableModal);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiVariableSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('props passing', () => {
    it('passes props down correctly to the ci table', () => {
      createComponent();

      expect(findCiVariableTable().props()).toEqual({
        entity: 'project',
        isLoading: defaultProps.isLoading,
        maxVariableLimit: defaultProps.maxVariableLimit,
        pageInfo: defaultProps.pageInfo,
        variables: defaultProps.variables,
      });
    });

    it('passes props down correctly to the ci modal', async () => {
      createComponent();

      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableModal().props()).toEqual({
        areEnvironmentsLoading: defaultProps.areEnvironmentsLoading,
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
    beforeEach(() => {
      createComponent();
    });

    it('passes down ADD mode when receiving an empty variable', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableModal().props('mode')).toBe(ADD_VARIABLE_ACTION);
    });

    it('passes down EDIT mode when receiving a variable', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findCiVariableModal().props('mode')).toBe(EDIT_VARIABLE_ACTION);
    });
  });

  describe('variable modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is hidden by default', () => {
      expect(findCiVariableModal().exists()).toBe(false);
    });

    it('shows modal when adding a new variable', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableModal().exists()).toBe(true);
    });

    it('shows modal when updating a variable', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findCiVariableModal().exists()).toBe(true);
    });

    it('hides modal when receiving the event from the modal', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      await findCiVariableModal().vm.$emit('hideModal');

      expect(findCiVariableModal().exists()).toBe(false);
    });
  });

  describe('variable events', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      eventName
      ${'add-variable'}
      ${'update-variable'}
      ${'delete-variable'}
    `('bubbles up the $eventName event', async ({ eventName }) => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      await findCiVariableModal().vm.$emit(eventName, newVariable);

      expect(wrapper.emitted(eventName)).toEqual([[newVariable]]);
    });
  });

  describe('pages events', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      eventName             | args
      ${'handle-prev-page'} | ${undefined}
      ${'handle-next-page'} | ${undefined}
      ${'sort-changed'}     | ${{ sortDesc: true }}
    `('bubbles up the $eventName event', async ({ args, eventName }) => {
      await findCiVariableTable().vm.$emit(eventName, args);

      expect(wrapper.emitted(eventName)).toEqual([[args]]);
    });
  });

  describe('environment events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('bubbles up the search event', async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      await findCiVariableModal().vm.$emit('search-environment-scope', 'staging');

      expect(wrapper.emitted('search-environment-scope')).toEqual([['staging']]);
    });
  });
});
