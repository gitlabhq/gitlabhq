import { shallowMount } from '@vue/test-utils';
import { pipelines } from 'test_fixtures/pipelines/pipelines.json';
import LegacyPipelineStage from '~/ci/pipeline_mini_graph/legacy_pipeline_stage.vue';
import PipelineStages from '~/ci/pipeline_mini_graph/pipeline_stages.vue';

const mockStages = pipelines[0].details.stages;

describe('Pipeline Stages', () => {
  let wrapper;

  const findLegacyPipelineStages = () => wrapper.findAllComponents(LegacyPipelineStage);
  const findPipelineStagesAt = (i) => findLegacyPipelineStages().at(i);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PipelineStages, {
      propsData: {
        stages: mockStages,
        ...props,
      },
    });
  };

  it('renders stages', () => {
    createComponent();

    expect(findLegacyPipelineStages()).toHaveLength(mockStages.length);
  });

  it('does not fail when stages are empty', () => {
    createComponent({ stages: [] });

    expect(wrapper.exists()).toBe(true);
    expect(findLegacyPipelineStages()).toHaveLength(0);
  });

  it('update dropdown is false by default', () => {
    createComponent();

    expect(findPipelineStagesAt(0).props('updateDropdown')).toBe(false);
    expect(findPipelineStagesAt(1).props('updateDropdown')).toBe(false);
  });

  it('update dropdown is set to true', () => {
    createComponent({ updateDropdown: true });

    expect(findPipelineStagesAt(0).props('updateDropdown')).toBe(true);
    expect(findPipelineStagesAt(1).props('updateDropdown')).toBe(true);
  });

  it('is merge train is false by default', () => {
    createComponent();

    expect(findPipelineStagesAt(0).props('isMergeTrain')).toBe(false);
    expect(findPipelineStagesAt(1).props('isMergeTrain')).toBe(false);
  });

  it('is merge train is set to true', () => {
    createComponent({ isMergeTrain: true });

    expect(findPipelineStagesAt(0).props('isMergeTrain')).toBe(true);
    expect(findPipelineStagesAt(1).props('isMergeTrain')).toBe(true);
  });
});
