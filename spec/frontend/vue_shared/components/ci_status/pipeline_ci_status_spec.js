import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { createMockSubscription as createMockApolloSubscription } from 'mock-apollo-client';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import PipelineCiStatus from '~/vue_shared/components/ci_status/pipeline_ci_status.vue';
import pipelineCiStatusQuery from '~/vue_shared/components/ci_status/graphql/pipeline_ci_status.query.graphql';
import pipelineCiStatusUpdatedSubscription from '~/vue_shared/components/ci_status/graphql/pipeline_ci_status_updated.subscription.graphql';
import { mockPipelineStatusResponse, mockPipelineStatusUpdatedResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('Pipeline CI Status', () => {
  let wrapper;
  let mockedSubscription;
  let apolloProvider;

  const defaultProps = {
    pipelineId: 'gid://gitlab/Ci::Pipeline/1255',
    projectFullPath: 'gitlab-org/gitlab',
    canSubscribe: true,
  };

  const error = new Error('GraphQL error');

  const successResolver = jest.fn().mockResolvedValue(mockPipelineStatusResponse);
  const errorResolver = jest.fn().mockRejectedValue(error);

  const createMockApolloProvider = (queryResolver) => {
    const requestHandlers = [[pipelineCiStatusQuery, queryResolver]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = (props = {}, queryResolver = successResolver) => {
    mockedSubscription = createMockApolloSubscription();
    apolloProvider = createMockApolloProvider(queryResolver);

    apolloProvider.defaultClient.setRequestHandler(
      pipelineCiStatusUpdatedSubscription,
      () => mockedSubscription,
    );

    wrapper = shallowMount(PipelineCiStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider,
    });
  };

  const findIcon = () => wrapper.findComponent(CiIcon);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('loading', () => {
    it('displays loading icon while fetching pipeline status', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('default', () => {
    it('does not display loading icon', async () => {
      createComponent();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays pipeline status', async () => {
      createComponent();

      await waitForPromises();

      expect(findIcon().exists()).toBe(true);
    });

    it('calls pipeline status query correctly', async () => {
      createComponent();

      await waitForPromises();

      expect(successResolver).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        pipelineId: 'gid://gitlab/Ci::Pipeline/1255',
      });
    });

    it('updates status when subscription updates', async () => {
      createComponent();

      await waitForPromises();

      expect(findIcon().props('status')).toStrictEqual({
        __typename: 'DetailedStatus',
        detailsPath: '/root/ci-project/-/pipelines/1257',
        icon: 'status_running',
        id: 'running-1257-1257',
        label: 'running',
        text: 'Running',
      });

      mockedSubscription.next(mockPipelineStatusUpdatedResponse);

      await waitForPromises();

      expect(findIcon().props('status')).toStrictEqual({
        __typename: 'DetailedStatus',
        detailsPath: '/root/simple-ci-project/-/pipelines/1257',
        icon: 'status_success',
        id: 'success-1255-1255',
        label: 'passed',
        text: 'Passed',
      });
    });
  });

  describe('error', () => {
    beforeEach(async () => {
      createComponent({}, errorResolver);

      await waitForPromises();
    });

    it('shows an error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred fetching the pipeline status.',
      });
    });

    it('reports an error', () => {
      expect(captureException).toHaveBeenCalledWith(error);
    });
  });
});
