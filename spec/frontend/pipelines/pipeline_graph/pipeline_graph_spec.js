import { shallowMount } from '@vue/test-utils';
import { pipelineData } from './mock_data';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import StagePill from '~/pipelines/components/pipeline_graph/stage_pill.vue';
import JobPill from '~/pipelines/components/pipeline_graph/job_pill.vue';

describe('pipeline graph component', () => {
  const defaultProps = { pipelineData };
  let wrapper;

  const createComponent = props => {
    return shallowMount(PipelineGraph, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findAllStagePills = () => wrapper.findAll(StagePill);
  const findAllJobPills = () => wrapper.findAll(JobPill);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with no data', () => {
    beforeEach(() => {
      wrapper = createComponent({ pipelineData: {} });
    });

    it('renders an empty section', () => {
      expect(wrapper.text()).toContain('No content to show');
      expect(findAllStagePills()).toHaveLength(0);
      expect(findAllJobPills()).toHaveLength(0);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });
    it('renders the right number of stage pills', () => {
      const expectedStagesLength = pipelineData.stages.length;

      expect(findAllStagePills()).toHaveLength(expectedStagesLength);
    });

    it('renders the right number of job pills', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = pipelineData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobPills()).toHaveLength(expectedJobsLength);
    });
  });
});
