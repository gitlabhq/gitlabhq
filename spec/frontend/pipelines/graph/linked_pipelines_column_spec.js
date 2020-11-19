import { shallowMount } from '@vue/test-utils';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import LinkedPipeline from '~/pipelines/components/graph/linked_pipeline.vue';
import { UPSTREAM } from '~/pipelines/components/graph/constants';
import mockData from './linked_pipelines_mock_data';

describe('Linked Pipelines Column', () => {
  const propsData = {
    columnTitle: 'Upstream',
    linkedPipelines: mockData.triggered,
    graphPosition: 'right',
    projectId: 19,
    type: UPSTREAM,
  };
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(LinkedPipelinesColumn, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the pipeline orientation', () => {
    const titleElement = wrapper.find('.linked-pipelines-column-title');

    expect(titleElement.text()).toBe(propsData.columnTitle);
  });

  it('renders the correct number of linked pipelines', () => {
    const linkedPipelineElements = wrapper.findAll(LinkedPipeline);

    expect(linkedPipelineElements.length).toBe(propsData.linkedPipelines.length);
  });

  it('renders cross project triangle when column is upstream', () => {
    expect(wrapper.find('.cross-project-triangle').exists()).toBe(true);
  });
});
