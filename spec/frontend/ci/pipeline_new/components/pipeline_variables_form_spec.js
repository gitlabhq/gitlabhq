import { GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { fetchPolicies } from '~/lib/graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { reportToSentry } from '~/ci/utils';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import PipelineVariablesForm from '~/ci/pipeline_new/components/pipeline_variables_form.vue';

Vue.use(VueApollo);
jest.mock('~/ci/utils');

describe('PipelineVariablesForm', () => {
  let wrapper;
  let mockApollo;
  let mockCiConfigVariables;

  const defaultProps = {
    projectPath: 'group/project',
    defaultBranch: 'main',
    refParam: 'feature',
  };

  const createComponent = async ({ props = {} } = {}) => {
    const handlers = [[ciConfigVariablesQuery, mockCiConfigVariables]];
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMount(PipelineVariablesForm, {
      apolloProvider: mockApollo,
      propsData: { ...defaultProps, ...props },
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findForm = () => wrapper.findComponent(GlFormGroup);

  beforeEach(() => {
    mockCiConfigVariables = jest.fn().mockResolvedValue({
      data: {
        project: {
          ciConfigVariables: [],
        },
      },
    });
  });

  describe('loading states', () => {
    it('is loading when query is in flight', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findForm().exists()).toBe(false);
    });

    it('is not loading after query completes', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
    });
  });

  describe('query configuration', () => {
    it('has correct apollo query configuration', async () => {
      await createComponent();
      const { apollo } = wrapper.vm.$options;

      expect(apollo.ciConfigVariables).toMatchObject({
        fetchPolicy: fetchPolicies.NO_CACHE,
        query: ciConfigVariablesQuery,
      });
    });

    it('makes query with correct variables', async () => {
      await createComponent();

      expect(mockCiConfigVariables).toHaveBeenCalledWith({
        fullPath: defaultProps.projectPath,
        ref: defaultProps.refParam,
      });
    });

    it('reports to sentry when query fails', async () => {
      mockCiConfigVariables = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      await createComponent();
      expect(reportToSentry).toHaveBeenCalledWith('PipelineVariablesForm', expect.any(Error));
    });
  });
});
