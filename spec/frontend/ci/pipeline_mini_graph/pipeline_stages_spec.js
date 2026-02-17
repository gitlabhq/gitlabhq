import { shallowMount } from '@vue/test-utils';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';
import PipelineStageDropdown from '~/ci/pipeline_mini_graph/pipeline_stage_dropdown.vue';

import { pipelineStage } from './mock_data';

describe('PipelineStages', () => {
  let wrapper;

  const defaultProps = {
    stages: [pipelineStage],
    isMergeTrain: false,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineStages, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findStages = () => wrapper.findAllComponents(PipelineStageDropdown);

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sends the necessary props to the stage', () => {
      expect(findStages().at(0).props()).toMatchObject({
        stage: defaultProps.stages[0],
        isMergeTrain: defaultProps.isMergeTrain,
      });
    });

    it('emits job-action-executed', () => {
      findStages().at(0).vm.$emit('job-action-executed');
      expect(wrapper.emitted('job-action-executed')).toHaveLength(1);
    });

    it('emits mini-graph-stage-click', () => {
      findStages().at(0).vm.$emit('mini-graph-stage-click');
      expect(wrapper.emitted('mini-graph-stage-click')).toHaveLength(1);
    });
  });
});
