import { shallowMount } from '@vue/test-utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciProjectVariables from '~/ci/ci_variable_list/components/ci_project_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';

import { GRAPHQL_PROJECT_TYPE } from '~/ci/ci_variable_list/constants';

const mockProvide = {
  projectFullPath: '/namespace/project',
  projectId: 1,
};

describe('Ci Project Variable wrapper', () => {
  let wrapper;

  const findCiShared = () => wrapper.findComponent(ciVariableShared);

  const createComponent = () => {
    wrapper = shallowMount(ciProjectVariables, {
      provide: mockProvide,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Passes down the correct props to ci_variable_shared', () => {
    expect(findCiShared().props()).toEqual({
      id: convertToGraphQLId(GRAPHQL_PROJECT_TYPE, mockProvide.projectId),
      areScopedVariablesAvailable: true,
      componentName: 'ProjectVariables',
      entity: 'project',
      fullPath: mockProvide.projectFullPath,
      hideEnvironmentScope: false,
      mutationData: wrapper.vm.$options.mutationData,
      queryData: wrapper.vm.$options.queryData,
      refetchAfterMutation: false,
    });
  });
});
