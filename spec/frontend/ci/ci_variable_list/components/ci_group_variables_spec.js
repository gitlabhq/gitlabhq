import { shallowMount } from '@vue/test-utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import ciGroupVariables from '~/ci/ci_variable_list/components/ci_group_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';

import { GRAPHQL_GROUP_TYPE } from '~/ci/ci_variable_list/constants';

const mockProvide = {
  glFeatures: {
    groupScopedCiVariables: false,
  },
  groupPath: '/group',
  groupId: 12,
};

describe('Ci Group Variable wrapper', () => {
  let wrapper;

  const findCiShared = () => wrapper.findComponent(ciVariableShared);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMount(ciGroupVariables, {
      provide: { ...mockProvide, ...provide },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('are passed down the correctly to ci_variable_shared', () => {
      expect(findCiShared().props()).toEqual({
        id: convertToGraphQLId(GRAPHQL_GROUP_TYPE, mockProvide.groupId),
        areScopedVariablesAvailable: false,
        componentName: 'GroupVariables',
        entity: 'group',
        fullPath: mockProvide.groupPath,
        hideEnvironmentScope: false,
        mutationData: wrapper.vm.$options.mutationData,
        queryData: wrapper.vm.$options.queryData,
        refetchAfterMutation: false,
      });
    });
  });

  describe('feature flag', () => {
    describe('When enabled', () => {
      beforeEach(() => {
        createComponent({ provide: { glFeatures: { groupScopedCiVariables: true } } });
      });

      it('Passes down `true` to variable shared component', () => {
        expect(findCiShared().props('areScopedVariablesAvailable')).toBe(true);
      });
    });

    describe('When disabled', () => {
      beforeEach(() => {
        createComponent({ provide: { glFeatures: { groupScopedCiVariables: false } } });
      });

      it('Passes down `false` to variable shared component', () => {
        expect(findCiShared().props('areScopedVariablesAvailable')).toBe(false);
      });
    });
  });
});
