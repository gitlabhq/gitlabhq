import { shallowMount } from '@vue/test-utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciProjectVariables from '~/ci/ci_variable_list/components/ci_project_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';

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

  it('Passes down the correct props to ci_variable_shared', () => {
    expect(findCiShared().props()).toEqual({
      id: convertToGraphQLId(TYPENAME_PROJECT, mockProvide.projectId),
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
