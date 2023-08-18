import { shallowMount } from '@vue/test-utils';
import CiVariableSettings from '~/ci/ci_variable_list/components/ci_variable_settings.vue';
import CiVariableModal from '~/ci/ci_variable_list/components/ci_variable_modal.vue';
import CiVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import CiVariableDrawer from '~/ci/ci_variable_list/components/ci_variable_drawer.vue';

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
    hasEnvScopeQuery: false,
    maxVariableLimit: 5,
    pageInfo: { after: '' },
    variables: mockVariablesWithScopes(projectString),
  };

  const findCiVariableDrawer = () => wrapper.findComponent(CiVariableDrawer);
  const findCiVariableTable = () => wrapper.findComponent(CiVariableTable);
  const findCiVariableModal = () => wrapper.findComponent(CiVariableModal);

  const createComponent = ({ props = {}, featureFlags = {} } = {}) => {
    wrapper = shallowMount(CiVariableSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          ciVariableDrawer: false,
          ...featureFlags,
        },
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
        hasEnvScopeQuery: defaultProps.hasEnvScopeQuery,
        hideEnvironmentScope: defaultProps.hideEnvironmentScope,
        variables: defaultProps.variables,
        mode: ADD_VARIABLE_ACTION,
        selectedVariable: {},
      });
    });

    it('passes props down correctly to the ci drawer', async () => {
      createComponent({ featureFlags: { ciVariableDrawer: true } });

      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableDrawer().props()).toEqual({
        areEnvironmentsLoading: defaultProps.areEnvironmentsLoading,
        areScopedVariablesAvailable: defaultProps.areScopedVariablesAvailable,
        environments: defaultProps.environments,
        hideEnvironmentScope: defaultProps.hideEnvironmentScope,
        mode: ADD_VARIABLE_ACTION,
        selectedVariable: {},
      });
    });
  });

  describe.each`
    bool     | flagStatus    | elementName | findElement
    ${false} | ${'disabled'} | ${'modal'}  | ${findCiVariableModal}
    ${true}  | ${'enabled'}  | ${'drawer'} | ${findCiVariableDrawer}
  `('when ciVariableDrawer feature flag is $flagStatus', ({ bool, elementName, findElement }) => {
    beforeEach(() => {
      createComponent({ featureFlags: { ciVariableDrawer: bool } });
    });

    it(`${elementName} is hidden by default`, () => {
      expect(findElement().exists()).toBe(false);
    });

    it(`shows ${elementName} when adding a new variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findElement().exists()).toBe(true);
    });

    it(`shows ${elementName} when updating a variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findElement().exists()).toBe(true);
    });

    it(`hides ${elementName} when closing the form`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findElement().isVisible()).toBe(true);

      await findElement().vm.$emit('close-form');

      expect(findElement().exists()).toBe(false);
    });

    it(`passes down ADD mode to ${elementName} when receiving an empty variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findElement().props('mode')).toBe(ADD_VARIABLE_ACTION);
    });

    it(`passes down EDIT mode to ${elementName} when receiving a variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findElement().props('mode')).toBe(EDIT_VARIABLE_ACTION);
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
