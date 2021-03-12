import { shallowMount } from '@vue/test-utils';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import PipelineStage from '~/pipelines/components/pipelines_list/pipeline_stage.vue';

const { pipelines } = getJSONFixture('pipelines/pipelines.json');
const mockStages = pipelines[0].details.stages;

describe('Pipeline Mini Graph', () => {
  let wrapper;

  const findPipelineStages = () => wrapper.findAll(PipelineStage);
  const findPipelineStagesAt = (i) => findPipelineStages().at(i);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PipelineMiniGraph, {
      propsData: {
        stages: mockStages,
        ...props,
      },
    });
  };

  it('renders stages', () => {
    createComponent();

    expect(findPipelineStages()).toHaveLength(mockStages.length);
  });

  it('renders stages with a custom class', () => {
    createComponent({ stagesClass: 'my-class' });

    expect(wrapper.findAll('.my-class')).toHaveLength(mockStages.length);
  });

  it('does not fail when stages are empty', () => {
    createComponent({ stages: [] });

    expect(wrapper.exists()).toBe(true);
    expect(findPipelineStages()).toHaveLength(0);
  });

  it('triggers events in "action request complete" in stages', () => {
    createComponent();

    findPipelineStagesAt(0).vm.$emit('pipelineActionRequestComplete');
    findPipelineStagesAt(1).vm.$emit('pipelineActionRequestComplete');

    expect(wrapper.emitted('pipelineActionRequestComplete')).toHaveLength(2);
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });
});
