import { pipelines } from 'test_fixtures/pipelines/pipelines.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';
import mockLinkedPipelines from '../legacy_linked_pipelines_mock_data';

const mockStages = pipelines[0].details.stages;

describe('Legacy Pipeline Mini Graph', () => {
  let wrapper;

  const findLegacyPipelineMiniGraph = () => wrapper.findComponent(LegacyPipelineMiniGraph);
  const findDownstream = () => wrapper.findComponent(DownstreamPipelines);
  const findPipelineStages = () => wrapper.findComponent(PipelineStages);
  const findUpstream = () => wrapper.findComponent(CiIcon);

  const findDownstreamArrowIcon = () => wrapper.find('[data-testid="downstream-arrow-icon"]');
  const findUpstreamArrowIcon = () => wrapper.find('[data-testid="upstream-arrow-icon"]');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(LegacyPipelineMiniGraph, {
      propsData: {
        stages: mockStages,
        ...props,
      },
    });
  };

  describe('rendered state without upstream or downstream pipelines', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render the pipeline stages', () => {
      expect(findPipelineStages().exists()).toBe(true);
    });

    it('should have the correct props', () => {
      expect(findLegacyPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: [],
        isMergeTrain: false,
        pipelinePath: '',
        stages: expect.any(Array),
        upstreamPipeline: undefined,
      });
    });

    it('should have no linked pipelines', () => {
      expect(findDownstream().exists()).toBe(false);
      expect(findUpstream().exists()).toBe(false);
    });

    it('should not render arrow icons', () => {
      expect(findUpstreamArrowIcon().exists()).toBe(false);
      expect(findDownstreamArrowIcon().exists()).toBe(false);
    });
  });

  describe('rendered state with upstream pipeline', () => {
    beforeEach(() => {
      createComponent({
        upstreamPipeline: mockLinkedPipelines.triggered_by,
      });
    });

    it('should have the correct props', () => {
      expect(findLegacyPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: [],
        isMergeTrain: false,
        pipelinePath: '',
        stages: expect.any(Array),
        upstreamPipeline: expect.any(Object),
      });
    });

    it('should render the upstream linked pipelines mini list only', () => {
      expect(findUpstream().exists()).toBe(true);
      expect(findDownstream().exists()).toBe(false);
    });

    it('should render an upstream arrow icon only', () => {
      expect(findDownstreamArrowIcon().exists()).toBe(false);
      expect(findUpstreamArrowIcon().exists()).toBe(true);
      expect(findUpstreamArrowIcon().props('name')).toBe('arrow-right');
    });
  });

  describe('rendered state with downstream pipelines', () => {
    beforeEach(() => {
      createComponent({
        downstreamPipelines: mockLinkedPipelines.triggered,
        pipelinePath: 'my/pipeline/path',
      });
    });

    it('should have the correct props', () => {
      expect(findLegacyPipelineMiniGraph().props()).toMatchObject({
        downstreamPipelines: expect.any(Array),
        isMergeTrain: false,
        pipelinePath: 'my/pipeline/path',
        stages: expect.any(Array),
        upstreamPipeline: undefined,
      });
    });

    it('should render the downstream linked pipelines mini list only', () => {
      expect(findDownstream().exists()).toBe(true);
      expect(findUpstream().exists()).toBe(false);
    });

    it('should render a downstream arrow icon only', () => {
      expect(findUpstreamArrowIcon().exists()).toBe(false);
      expect(findDownstreamArrowIcon().exists()).toBe(true);
      expect(findDownstreamArrowIcon().props('name')).toBe('arrow-right');
    });
  });
});
