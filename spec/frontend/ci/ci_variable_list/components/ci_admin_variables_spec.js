import { shallowMount } from '@vue/test-utils';

import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
} from '~/ci/ci_variable_list/constants';
import ciAdminVariables from '~/ci/ci_variable_list/components/ci_admin_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';
import addAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_add_variable.mutation.graphql';
import deleteAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_delete_variable.mutation.graphql';
import updateAdminVariable from '~/ci/ci_variable_list/graphql/mutations/admin_update_variable.mutation.graphql';
import getAdminVariables from '~/ci/ci_variable_list/graphql/queries/variables.query.graphql';

describe('Ci Project Variable wrapper', () => {
  let wrapper;

  const findCiShared = () => wrapper.findComponent(ciVariableShared);

  const createComponent = () => {
    wrapper = shallowMount(ciAdminVariables);
  };

  beforeEach(() => {
    createComponent();
  });

  it('Passes down the correct props to ci_variable_shared', () => {
    expect(findCiShared().props()).toEqual({
      areScopedVariablesAvailable: false,
      componentName: 'InstanceVariables',
      entity: '',
      hideEnvironmentScope: true,
      mutationData: {
        [ADD_MUTATION_ACTION]: addAdminVariable,
        [UPDATE_MUTATION_ACTION]: updateAdminVariable,
        [DELETE_MUTATION_ACTION]: deleteAdminVariable,
      },
      queryData: {
        ciVariables: {
          lookup: expect.any(Function),
          query: getAdminVariables,
        },
      },
      refetchAfterMutation: true,
      fullPath: null,
      id: null,
    });
  });
});
