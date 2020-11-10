import { shallowMount } from '@vue/test-utils';
import { pipelineData, singleStageData } from './mock_data';
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
  const findAllStageBackgroundElements = () => wrapper.findAll('[data-testid="stage-background"]');
  const findStageBackgroundElementAt = index => findAllStageBackgroundElements().at(index);
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
      expect(wrapper.text()).toContain(
        'The visualization will appear in this tab when the CI/CD configuration file is populated with valid syntax.',
      );
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

    it.each`
      cssClass                       | expectedState
      ${'gl-rounded-bottom-left-6'}  | ${true}
      ${'gl-rounded-top-left-6'}     | ${true}
      ${'gl-rounded-top-right-6'}    | ${false}
      ${'gl-rounded-bottom-right-6'} | ${false}
    `(
      'rounds corner: $class should be $expectedState on the first element',
      ({ cssClass, expectedState }) => {
        const classes = findStageBackgroundElementAt(0).classes();

        expect(classes.includes(cssClass)).toBe(expectedState);
      },
    );

    it.each`
      cssClass                       | expectedState
      ${'gl-rounded-bottom-left-6'}  | ${false}
      ${'gl-rounded-top-left-6'}     | ${false}
      ${'gl-rounded-top-right-6'}    | ${true}
      ${'gl-rounded-bottom-right-6'} | ${true}
    `(
      'rounds corner: $class should be $expectedState on the last element',
      ({ cssClass, expectedState }) => {
        const classes = findStageBackgroundElementAt(pipelineData.stages.length - 1).classes();

        expect(classes.includes(cssClass)).toBe(expectedState);
      },
    );

    it('renders the right number of job pills', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = pipelineData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobPills()).toHaveLength(expectedJobsLength);
    });
  });

  describe('with only one stage', () => {
    beforeEach(() => {
      wrapper = createComponent({ pipelineData: singleStageData });
    });

    it.each`
      cssClass                       | expectedState
      ${'gl-rounded-bottom-left-6'}  | ${true}
      ${'gl-rounded-top-left-6'}     | ${true}
      ${'gl-rounded-top-right-6'}    | ${true}
      ${'gl-rounded-bottom-right-6'} | ${true}
    `(
      'rounds corner: $class should be $expectedState on the only element',
      ({ cssClass, expectedState }) => {
        const classes = findStageBackgroundElementAt(0).classes();

        expect(classes.includes(cssClass)).toBe(expectedState);
      },
    );
  });
});
