import { shallowMount } from '@vue/test-utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciProjectVariables from '~/ci/ci_variable_list/components/ci_project_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
} from '~/ci/ci_variable_list/constants';
import { getProjectEnvironments } from '~/ci/common/private/ci_environments_dropdown';
import getProjectVariables from '~/ci/ci_variable_list/graphql/queries/project_variables.query.graphql';
import addProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_add_variable.mutation.graphql';
import deleteProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_delete_variable.mutation.graphql';
import updateProjectVariable from '~/ci/ci_variable_list/graphql/mutations/project_update_variable.mutation.graphql';

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
      mutationData: {
        [ADD_MUTATION_ACTION]: addProjectVariable,
        [UPDATE_MUTATION_ACTION]: updateProjectVariable,
        [DELETE_MUTATION_ACTION]: deleteProjectVariable,
      },
      queryData: {
        ciVariables: {
          lookup: expect.any(Function),
          query: getProjectVariables,
        },
        environments: {
          lookup: expect.any(Function),
          query: getProjectEnvironments,
        },
      },
      refetchAfterMutation: false,
    });
  });
});
