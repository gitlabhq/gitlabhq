import { shallowMount } from '@vue/test-utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciGroupVariables from '~/ci/ci_variable_list/components/ci_group_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';
import {
  ADD_MUTATION_ACTION,
  DELETE_MUTATION_ACTION,
  UPDATE_MUTATION_ACTION,
} from '~/ci/ci_variable_list/constants';
import { getGroupEnvironments } from '~/ci/common/private/ci_environments_dropdown';
import getGroupVariables from '~/ci/ci_variable_list/graphql/queries/group_variables.query.graphql';
import addGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_add_variable.mutation.graphql';
import deleteGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_delete_variable.mutation.graphql';
import updateGroupVariable from '~/ci/ci_variable_list/graphql/mutations/group_update_variable.mutation.graphql';

const mockProvide = {
  groupPath: '/group',
  groupId: 12,
};

describe('Ci Group Variable wrapper', () => {
  let wrapper;

  const findCiShared = () => wrapper.findComponent(ciVariableShared);

  const createComponent = ({ featureFlags } = {}) => {
    wrapper = shallowMount(ciGroupVariables, {
      provide: {
        ...mockProvide,
        glFeatures: {
          groupScopedCiVariables: false,
          ...featureFlags,
        },
      },
    });
  };

  describe('Props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('are passed down the correctly to ci_variable_shared', () => {
      expect(findCiShared().props()).toEqual({
        id: convertToGraphQLId(TYPENAME_GROUP, mockProvide.groupId),
        areScopedVariablesAvailable: false,
        componentName: 'GroupVariables',
        entity: 'group',
        fullPath: mockProvide.groupPath,
        hideEnvironmentScope: false,
        mutationData: {
          [ADD_MUTATION_ACTION]: addGroupVariable,
          [UPDATE_MUTATION_ACTION]: updateGroupVariable,
          [DELETE_MUTATION_ACTION]: deleteGroupVariable,
        },
        queryData: {
          ciVariables: {
            lookup: expect.any(Function),
            query: getGroupVariables,
          },
          environments: {
            lookup: expect.any(Function),
            query: getGroupEnvironments,
          },
        },
        refetchAfterMutation: false,
      });
    });
  });

  describe('groupScopedCiVariables feature flag', () => {
    describe('When enabled', () => {
      beforeEach(() => {
        createComponent({ featureFlags: { groupScopedCiVariables: true } });
      });

      it('Passes down `true` to variable shared component', () => {
        expect(findCiShared().props('areScopedVariablesAvailable')).toBe(true);
      });
    });

    describe('When disabled', () => {
      beforeEach(() => {
        createComponent();
      });

      it('Passes down `false` to variable shared component', () => {
        expect(findCiShared().props('areScopedVariablesAvailable')).toBe(false);
      });
    });
  });
});
