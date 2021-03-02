import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { trimText } from 'helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import ArtifactsApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import Deployment from '~/vue_merge_request_widget/components/deployment/deployment.vue';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import { mockStore } from '../mock_data';

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
      const expectedProps = mockStore.deployments.map((dep) =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: false,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-pre-deployment');

      expect(deployments.wrappers.map((x) => x.props())).toEqual(expectedProps);
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

    it('sanitizes the targetBranch', () => {
      factory({
        isPostMerge: true,
        mr: {
          ...mockStore,
          targetBranch: 'Foo<script>alert("XSS")</script>',
        },
      });

      expect(wrapper.find(MrWidgetPipeline).props().sourceBranchLink).toBe('Foo');
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.postMergeDeployments.map((dep) =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: true,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-post-deployment');

      expect(deployments.wrappers.map((x) => x.props())).toEqual(expectedProps);
    });
  });

  describe('with artifacts path', () => {
    it('renders the artifacts app', () => {
      factory();

      expect(wrapper.find(ArtifactsApp).isVisible()).toBe(true);
    });
  });
  describe('with many deployments', () => {
    let deployments;
    let collapsibleExtension;

    beforeEach(() => {
      deployments = [
        ...mockStore.deployments,
        ...mockStore.deployments.map((deployment) => ({
          ...deployment,
          id: deployment.id + mockStore.deployments.length,
        })),
      ];
      factory({
        mr: {
          ...mockStore,
          deployments,
        },
      });
      collapsibleExtension = wrapper.find('[data-testid="mr-collapsed-deployments"]');
    });

    it('renders them collapsed', () => {
      expect(collapsibleExtension.exists()).toBe(true);
      expect(trimText(collapsibleExtension.text())).toBe(
        `${deployments.length} environments impacted. View all environments.`,
      );
    });

    it('shows them when clicked', async () => {
      const expectedProps = deployments.map((dep) =>
        expect.objectContaining({
          deployment: dep,
          showMetrics: false,
        }),
      );
      await collapsibleExtension.find('button').trigger('click');

      const deploymentWrappers = collapsibleExtension.findAllComponents(Deployment);

      expect(deploymentWrappers.wrappers.map((x) => x.props())).toEqual(expectedProps);
      deploymentWrappers.wrappers.forEach((x) => {
        expect(x.text()).toEqual(expect.any(String));
        expect(x.text()).not.toBe('');
      });
    });
  });
});
