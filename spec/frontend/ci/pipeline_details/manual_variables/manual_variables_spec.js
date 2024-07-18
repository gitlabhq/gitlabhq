import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ManualVariablesApp from '~/ci/pipeline_details/manual_variables/manual_variables.vue';
import EmptyState from '~/ci/pipeline_details/manual_variables/empty_state.vue';
import VariableTable from '~/ci/pipeline_details/manual_variables/variable_table.vue';
import GetManualVariablesQuery from '~/ci/pipeline_details/manual_variables/graphql/queries/get_manual_variables.query.graphql';
import { generateVariablePairs, mockManualVariableConnection } from './mock_data';

Vue.use(VueApollo);

describe('ManualVariableApp', () => {
  let wrapper;
  const mockResolver = jest.fn();
  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[GetManualVariablesQuery, resolver]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (variables = []) => {
    mockResolver.mockResolvedValue(mockManualVariableConnection(variables));
    wrapper = shallowMount(ManualVariablesApp, {
      provide: {
        manualVariablesCount: variables.length,
        projectPath: 'root/ci-project',
        pipelineIid: '1',
      },
      apolloProvider: createMockApolloProvider(mockResolver),
    });
  };

  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findVariableTable = () => wrapper.findComponent(VariableTable);

  afterEach(() => {
    mockResolver.mockClear();
  });

  describe('when component is created', () => {
    it('renders empty state when no variables were found', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders loading state when variables were found', () => {
      createComponent(generateVariablePairs(1));

      expect(findEmptyState().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findVariableTable().exists()).toBe(false);
    });

    it('renders variable table when variables were retrieved', async () => {
      createComponent(generateVariablePairs(1));
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findVariableTable().exists()).toBe(true);
    });
  });
});
