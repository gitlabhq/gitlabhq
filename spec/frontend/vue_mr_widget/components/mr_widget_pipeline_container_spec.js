import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import ArtifactsApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import { mockStore } from '../mock_data';
import axios from '~/lib/utils/axios_utils';

describe('MrWidgetPipelineContainer', () => {
  let wrapper;
  let mock;

  const factory = (props = {}) => {
    wrapper = mount(MrWidgetPipelineContainer, {
      propsData: {
        mr: { ...mockStore },
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(200, {});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when pre merge', () => {
    beforeEach(() => {
      factory();
    });

    it('renders pipeline', () => {
      expect(wrapper.find(MrWidgetPipeline).exists()).toBe(true);
      expect(wrapper.find(MrWidgetPipeline).props()).toMatchObject({
        pipeline: mockStore.pipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        ciStatus: mockStore.ciStatus,
        hasCi: mockStore.hasCI,
        sourceBranch: mockStore.sourceBranch,
        sourceBranchLink: mockStore.sourceBranchLink,
      });
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.deployments.map(dep =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: false,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-pre-deployment');

      expect(deployments.wrappers.map(x => x.props())).toEqual(expectedProps);
    });
  });

  describe('when post merge', () => {
    beforeEach(() => {
      factory({
        isPostMerge: true,
      });
    });

    it('renders pipeline', () => {
      expect(wrapper.find(MrWidgetPipeline).exists()).toBe(true);
      expect(wrapper.find(MrWidgetPipeline).props()).toMatchObject({
        pipeline: mockStore.mergePipeline,
        pipelineCoverageDelta: mockStore.pipelineCoverageDelta,
        ciStatus: mockStore.ciStatus,
        hasCi: mockStore.hasCI,
        sourceBranch: mockStore.targetBranch,
        sourceBranchLink: mockStore.targetBranch,
      });
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.postMergeDeployments.map(dep =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: true,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-post-deployment');

      expect(deployments.wrappers.map(x => x.props())).toEqual(expectedProps);
    });
  });

  describe('with artifacts path', () => {
    it('renders the artifacts app', () => {
      expect(wrapper.find(ArtifactsApp).isVisible()).toBe(true);
    });
  });
});
