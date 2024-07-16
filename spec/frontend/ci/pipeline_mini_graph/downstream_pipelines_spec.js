import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import { downstreamPipelines, singlePipeline } from './mock_data';

describe('Downstream Pipelines', () => {
  let wrapper;

  const findCiIcons = () => wrapper.findAllComponents(CiIcon);
  const findPipelineCounter = () => wrapper.findByTestId('downstream-pipeline-counter');
  const findDownstreamPipeline = () => wrapper.findByTestId('downstream-pipelines');
  const findDownstreamPipelines = () => wrapper.findAllByTestId('downstream-pipelines');
  const findDownstreamPipelinesComponent = () => wrapper.findComponent(DownstreamPipelines);

  const createComponent = (props = {}) => {
    wrapper = mountExtended(DownstreamPipelines, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('when passed 1 downstream pipeline as props', () => {
    beforeEach(() => {
      createComponent({
        pipelines: [singlePipeline],
        pipelinePath: 'my/pipeline/path',
      });
    });

    it('should render the correct ci status icon', () => {
      const findIcon = () => wrapper.findByTestId('status_success_borderless-icon');

      expect(findIcon().exists()).toBe(true);
    });

    it('should have the correct title assigned for the tooltip', () => {
      expect(findDownstreamPipeline().attributes('title')).toBe('trigger-downstream - passed');
    });

    it('should not render the pipeline counter', () => {
      expect(findPipelineCounter().exists()).toBe(false);
    });
  });

  describe('when passed  > 3 downstream pipelines as props', () => {
    beforeEach(() => {
      createComponent({
        pipelines: downstreamPipelines,
        pipelinePath: 'my/pipeline/path',
      });
    });

    describe('pipelines', () => {
      it('should render three pipeline items', () => {
        expect(findDownstreamPipelines().exists()).toBe(true);
        expect(findDownstreamPipelines()).toHaveLength(3);
      });

      it('should render three ci status icons', () => {
        expect(findCiIcons().exists()).toBe(true);
        expect(findCiIcons()).toHaveLength(3);
      });

      it('should correctly trim pipelines', () => {
        expect(findDownstreamPipelinesComponent().props('pipelines')).toHaveLength(4);
        expect(findDownstreamPipelines()).toHaveLength(3);
      });
    });

    describe('pipeline counter', () => {
      it('should render the pipeline counter', () => {
        expect(findPipelineCounter().exists()).toBe(true);
      });

      it('should render the correct tooltip text', () => {
        const tooltip = getBinding(findPipelineCounter().element, 'gl-tooltip');

        expect(tooltip.value.title).toContain('more downstream pipelines');
      });

      it('should set the correct pipeline path', () => {
        expect(findPipelineCounter().attributes('href')).toBe('my/pipeline/path');
      });
    });
  });
});
