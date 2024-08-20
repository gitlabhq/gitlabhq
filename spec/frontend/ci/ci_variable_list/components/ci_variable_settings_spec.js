import { shallowMount } from '@vue/test-utils';
import CiVariableSettings from '~/ci/ci_variable_list/components/ci_variable_settings.vue';
import CiVariableTable from '~/ci/ci_variable_list/components/ci_variable_table.vue';
import CiVariableDrawer from '~/ci/ci_variable_list/components/ci_variable_drawer.vue';
import {
  ADD_VARIABLE_ACTION,
  EDIT_VARIABLE_ACTION,
  projectString,
} from '~/ci/ci_variable_list/constants';
import { mapEnvironmentNames } from '~/ci/common/private/ci_environments_dropdown';
import { mockEnvs, mockVariablesWithScopes, newVariable } from '../mocks';

describe('Ci variable table', () => {
  let wrapper;

  const defaultProps = {
    areEnvironmentsLoading: false,
    areHiddenVariablesAvailable: false,
    areScopedVariablesAvailable: true,
    entity: 'project',
    environments: mapEnvironmentNames(mockEnvs),
    hideEnvironmentScope: false,
    isLoading: false,
    maxVariableLimit: 5,
    mutationResponse: { message: 'Success', hasError: false },
    pageInfo: { after: '' },
    variables: mockVariablesWithScopes(projectString),
  };

  const findCiVariableDrawer = () => wrapper.findComponent(CiVariableDrawer);
  const findCiVariableTable = () => wrapper.findComponent(CiVariableTable);

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

    it('passes props down correctly to the ci drawer', async () => {
      createComponent();

      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableDrawer().props()).toEqual({
        areEnvironmentsLoading: defaultProps.areEnvironmentsLoading,
        areHiddenVariablesAvailable: defaultProps.areHiddenVariablesAvailable,
        areScopedVariablesAvailable: defaultProps.areScopedVariablesAvailable,
        environments: defaultProps.environments,
        hideEnvironmentScope: defaultProps.hideEnvironmentScope,
        mode: ADD_VARIABLE_ACTION,
        mutationResponse: defaultProps.mutationResponse,
        selectedVariable: {},
      });
    });
  });

  describe('drawer behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`drawer is hidden by default`, () => {
      expect(findCiVariableDrawer().exists()).toBe(false);
    });

    it(`shows drawer when adding a new variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableDrawer().exists()).toBe(true);
    });

    it(`shows drawer when updating a variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findCiVariableDrawer().exists()).toBe(true);
    });

    it(`hides drawer when closing the form`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableDrawer().isVisible()).toBe(true);

      await findCiVariableDrawer().vm.$emit('close-form');

      expect(findCiVariableDrawer().exists()).toBe(false);
    });

    it(`passes down ADD mode to drawer when receiving an empty variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable');

      expect(findCiVariableDrawer().props('mode')).toBe(ADD_VARIABLE_ACTION);
    });

    it(`passes down EDIT mode to drawer when receiving a variable`, async () => {
      await findCiVariableTable().vm.$emit('set-selected-variable', newVariable);

      expect(findCiVariableDrawer().props('mode')).toBe(EDIT_VARIABLE_ACTION);
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

      await findCiVariableDrawer().vm.$emit(eventName, newVariable);

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

      await findCiVariableDrawer().vm.$emit('search-environment-scope', 'staging');

      expect(wrapper.emitted('search-environment-scope')).toEqual([['staging']]);
    });
  });
});
