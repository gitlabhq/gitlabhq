import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import DownstreamPipelines from '~/ci/pipeline_mini_graph/downstream_pipelines.vue';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';

import { pipelineStage, singlePipeline, mockDownstreamPipelinesGraphql } from './mock_data';

Vue.use(VueApollo);

describe('PipelineMiniGraph', () => {
  let wrapper;

  const defaultProps = {
    downstreamPipelines: mockDownstreamPipelinesGraphql.nodes,
    isMergeTrain: true,
    pipelinePath: '/path/to/pipeline',
    pipelineStages: [pipelineStage],
    upstreamPipeline: singlePipeline,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(PipelineMiniGraph, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findUpstream = () => wrapper.findComponent(CiIcon);
  const findDownstream = () => wrapper.findComponent(DownstreamPipelines);
  const findStages = () => wrapper.findComponent(PipelineStages);

  describe('on render', () => {
    describe('stages', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders stages', () => {
        expect(findStages().exists()).toBe(true);
      });

      it('sends the necessary props', () => {
        expect(findStages().props()).toMatchObject({
          isMergeTrain: defaultProps.isMergeTrain,
          stages: defaultProps.pipelineStages,
        });
      });

      it('emits miniGraphStageClick', () => {
        findStages().vm.$emit('miniGraphStageClick');
        expect(wrapper.emitted('miniGraphStageClick')).toHaveLength(1);
      });
    });

    describe('upstream', () => {
      it('renders upstream if available', () => {
        createComponent();
        expect(findUpstream().exists()).toBe(true);
      });

      it('does not render upstream if not available', () => {
        createComponent({
          props: { upstreamPipeline: {} },
        });
        expect(findUpstream().exists()).toBe(false);
      });
    });

    describe('downstream', () => {
      it('renders downstream if available', () => {
        createComponent();
        expect(findDownstream().exists()).toBe(true);
      });

      it('sends the necessary props', () => {
        createComponent();
        expect(findDownstream().props()).toMatchObject({
          pipelines: expect.any(Array),
          pipelinePath: expect.any(String),
        });
      });

      it('keeps the latest downstream pipelines', () => {
        createComponent();
        expect(findDownstream().props('pipelines')).toHaveLength(2);
      });

      it('does not render downstream if not available', () => {
        createComponent({
          props: { downstreamPipelines: [] },
        });
        expect(findDownstream().exists()).toBe(false);
      });
    });
  });
});
