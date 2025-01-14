import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

import ArtifactsApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import DeploymentList from '~/vue_merge_request_widget/components/deployment/deployment_list.vue';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';

import getMergePipeline from '~/vue_merge_request_widget/queries/get_merge_pipeline.query.graphql';
import { mockStore, mockMergePipelineQueryResponse } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('MrWidgetPipelineContainer', () => {
  let wrapper;
  let mock;
  let mergePipelineResponse;

  const createComponent = async ({
    props = {},
    mergePipelineHandler = mergePipelineResponse,
  } = {}) => {
    const handlers = [[getMergePipeline, mergePipelineHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = extendedWrapper(
      mount(MrWidgetPipelineContainer, {
        propsData: {
          mr: { ...mockStore },
          ...props,
        },
        apolloProvider: mockApollo,
      }),
    );

    await waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(HTTP_STATUS_OK, {});
  });

  const findCIErrorMessage = () => wrapper.findByTestId('ci-error-message');
  const findDeploymentList = () => wrapper.findComponent(DeploymentList);
  const findMrWidgetPipeline = () => wrapper.findComponent(MrWidgetPipeline);

  describe('when pre merge', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders pipeline', () => {
      expect(findMrWidgetPipeline().exists()).toBe(true);
    });

    it('sends correct props to the pipeline widget', () => {
      // pipeline from mr store
      expect(findMrWidgetPipeline().props()).toMatchObject({
        pipeline: mockStore.pipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        pipelineEtag: mockStore.pipelineEtag,
        ciStatus: mockStore.ciStatus,
        hasCi: mockStore.hasCI,
        sourceBranch: mockStore.sourceBranch,
        sourceBranchLink: mockStore.sourceBranchLink,
        retargeted: false,
        targetProjectId: 1,
        iid: 1,
      });
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.deployments.map((dep) =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: false,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-pre-deployment');

      expect(findDeploymentList().exists()).toBe(true);
      expect(findDeploymentList().props('deployments')).toBe(mockStore.deployments);

      expect(deployments.wrappers.map((x) => x.props())).toEqual(expectedProps);
    });
  });

  describe('when post merge', () => {
    beforeEach(async () => {
      mergePipelineResponse = jest.fn();
      mergePipelineResponse.mockResolvedValue(mockMergePipelineQueryResponse);

      await createComponent({
        props: {
          isPostMerge: true,
          mr: {
            ...mockStore,
            pipeline: {},
            ciStatus: undefined,
          },
        },
      });
    });

    it('renders pipeline', () => {
      expect(findMrWidgetPipeline().exists()).toBe(true);
      expect(findCIErrorMessage().exists()).toBe(false);
    });

    it('sends correct props to the pipeline widget', () => {
      expect(findMrWidgetPipeline().props()).toMatchObject({
        ciStatus: mockStore.mergePipeline.details.status.text,
        hasCi: mockStore.hasCI,
        pipeline: mockStore.mergePipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        pipelineEtag: mockStore.pipelineEtag,
        sourceBranch: mockStore.targetBranch,
        sourceBranchLink: mockStore.targetBranch,
      });
    });

    it('sanitizes the targetBranch', () => {
      createComponent({
        props: {
          isPostMerge: true,
          mr: {
            ...mockStore,
            targetBranch: 'Foo<script>alert("XSS")</script>',
          },
        },
      });
      expect(wrapper.findComponent(MrWidgetPipeline).props().sourceBranchLink).toBe('Foo');
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.postMergeDeployments.map((dep) =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: true,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-post-deployment');

      expect(findDeploymentList().exists()).toBe(true);
      expect(findDeploymentList().props('deployments')).toBe(mockStore.postMergeDeployments);
      expect(deployments.wrappers.map((x) => x.props())).toEqual(expectedProps);
    });
  });

  describe('with artifacts path', () => {
    it('renders the artifacts app', () => {
      createComponent();

      expect(wrapper.findComponent(ArtifactsApp).isVisible()).toBe(true);
    });
  });
});
