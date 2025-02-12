import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { createAlert } from '~/alert';
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
import * as sharedGraphQlUtils from '~/graphql_shared/utils';
import { mockStore, mockMergePipelineQueryResponse } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('MrWidgetPipelineContainer', () => {
  let wrapper;
  let mock;
  let mergePipelineResponse;

  const createComponent = async ({
    ciGraphqlPipelineMiniGraph = true,
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
        provide: {
          glFeatures: {
            ciGraphqlPipelineMiniGraph,
          },
        },
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
      const pipelineMiniGraphVariables = {
        iid: mockStore.pipelineIid,
        fullPath: mockStore.pipelineProjectPath,
      };

      expect(findMrWidgetPipeline().props()).toMatchObject({
        pipeline: mockStore.pipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        pipelineEtag: mockStore.pipelineEtag,
        pipelineMiniGraphVariables,
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

    describe('with feature flag disabled', () => {
      it('does not fire the query', async () => {
        await createComponent({
          ciGraphqlPipelineMiniGraph: false,
          props: {
            isPostMerge: true,
          },
        });

        expect(wrapper.vm.$apollo.queries.mergePipeline.skip).toBe(true);
      });
    });

    describe('with feature flag enabled', () => {
      it('fires the query', () => {
        const queryVariables = {
          id: `gid://gitlab/Ci::Pipeline/${mockStore.mergePipeline.id}`,
          fullPath: mockStore.targetProjectFullPath,
        };

        expect(mergePipelineResponse).toHaveBeenCalledWith(queryVariables);
      });

      describe('polling', () => {
        it('toggles query polling with visibility check', async () => {
          jest.spyOn(sharedGraphQlUtils, 'toggleQueryPollingByVisibility');

          await createComponent();

          expect(sharedGraphQlUtils.toggleQueryPollingByVisibility).toHaveBeenCalledTimes(1);
        });
      });

      describe('when the merge pipeline query is unsuccessful', () => {
        const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

        it('throws an error for the query', async () => {
          await createComponent({
            mergePipelineHandler: failedHandler,
            props: {
              isPostMerge: true,
            },
          });

          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching the merge pipeline.',
          });
        });
      });
    });

    it('renders pipeline', () => {
      expect(findMrWidgetPipeline().exists()).toBe(true);
      expect(findCIErrorMessage().exists()).toBe(false);
    });

    it('sends correct props to the pipeline widget', () => {
      const { data } = mockMergePipelineQueryResponse;

      const pipelineMiniGraphVariables = {
        iid: data.project.pipeline.iid,
        fullPath: data.project.pipeline.project.fullPath,
      };

      expect(findMrWidgetPipeline().props()).toMatchObject({
        ciStatus: mockStore.mergePipeline.details.status.text,
        hasCi: mockStore.hasCI,
        pipeline: mockStore.mergePipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        pipelineEtag: mockStore.pipelineEtag,
        pipelineMiniGraphVariables,
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

    it('sanitizes the targetBranch output', () => {
      createComponent({
        props: {
          isPostMerge: true,
          mr: {
            ...mockStore,
            targetBranch:
              "x<i/class='js-unsanitized-code'/data-context-commits-path=/$PROJECT_PATH/-/raw/main/data.json>",
          },
        },
      });

      expect(wrapper.find('.js-unsanitized-code').exists()).toBe(false);
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
