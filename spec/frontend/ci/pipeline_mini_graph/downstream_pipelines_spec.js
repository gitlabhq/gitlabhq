import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import DownstreamPipelineDropdown from '~/ci/pipeline_mini_graph/downstream_pipeline_dropdown.vue';
import { downstreamPipelines, singlePipeline } from './mock_data';

describe('Downstream Pipelines', () => {
  let wrapper;

  const findDownstreamDropdowns = () => wrapper.findAllComponents(DownstreamPipelineDropdown);
  const findPipelineCounter = () => wrapper.findByTestId('downstream-pipeline-counter');
  const findDownstreamPipelinesComponent = () => wrapper.findComponent(DownstreamPipelines);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(DownstreamPipelines, {
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

    it('should render 1 dropdown', () => {
      expect(findDownstreamDropdowns()).toHaveLength(1);
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
      it('should render three dropdowns', () => {
        expect(findDownstreamDropdowns().exists()).toBe(true);
        expect(findDownstreamDropdowns()).toHaveLength(3);
      });

      it('should correctly trim pipelines', () => {
        expect(findDownstreamPipelinesComponent().props('pipelines')).toHaveLength(4);
        expect(findDownstreamDropdowns()).toHaveLength(3);
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
