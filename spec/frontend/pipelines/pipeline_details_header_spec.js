import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineDetailsHeader from '~/pipelines/components/pipeline_details_header.vue';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import getPipelineDetailsQuery from '~/pipelines/graphql/queries/get_pipeline_header_data.query.graphql';
import { mockSuccessfulPipelineHeader } from './mock_data';

Vue.use(VueApollo);

describe('Pipeline details header', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(mockSuccessfulPipelineHeader);

  const findStatus = () => wrapper.findComponent(CiBadgeLink);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const defaultHandlers = [[getPipelineDetailsQuery, successHandler]];

  const defaultProvideOptions = {
    pipelineId: '14',
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
    },
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers) => {
    wrapper = shallowMount(PipelineDetailsHeader, {
      provide: {
        ...defaultProvideOptions,
      },
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('loading state', () => {
    it('shows a loading state while graphQL is fetching initial data', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loaded state', () => {
    it('does not display loading icon', async () => {
      createComponent();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays pipeline status', async () => {
      createComponent();

      await waitForPromises();

      expect(findStatus().exists()).toBe(true);
    });
  });
});
