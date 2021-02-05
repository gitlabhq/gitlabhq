import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { CI_CONFIG_STATUS_INVALID, CI_CONFIG_STATUS_VALID } from '~/pipeline_editor/constants';
import { DRAW_FAILURE, EMPTY_PIPELINE_DATA, INVALID_CI_CONFIG } from '~/pipelines/constants';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import StagePill from '~/pipelines/components/pipeline_graph/stage_pill.vue';
import JobPill from '~/pipelines/components/pipeline_graph/job_pill.vue';
import { pipelineData, singleStageData } from './mock_data';

describe('pipeline graph component', () => {
  const defaultProps = { pipelineData };
  let wrapper;

  const createComponent = (props = defaultProps) => {
    return shallowMount(PipelineGraph, {
      propsData: {
        ...props,
      },
    });
  };

  const findPipelineGraph = () => wrapper.find('[data-testid="graph-container"]');
  const findAlert = () => wrapper.find(GlAlert);
  const findAllStagePills = () => wrapper.findAll(StagePill);
  const findAllStageBackgroundElements = () => wrapper.findAll('[data-testid="stage-background"]');
  const findStageBackgroundElementAt = (index) => findAllStageBackgroundElements().at(index);
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
      expect(wrapper.text()).toBe(wrapper.vm.$options.errorTexts[EMPTY_PIPELINE_DATA]);
      expect(findPipelineGraph().exists()).toBe(false);
      expect(findAllStagePills()).toHaveLength(0);
      expect(findAllJobPills()).toHaveLength(0);
    });
  });

  describe('with `INVALID` status', () => {
    beforeEach(() => {
      wrapper = createComponent({ pipelineData: { status: CI_CONFIG_STATUS_INVALID } });
    });

    it('renders an error message and does not render the graph', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(wrapper.vm.$options.errorTexts[INVALID_CI_CONFIG]);
      expect(findPipelineGraph().exists()).toBe(false);
    });
  });

  describe('with `VALID` status', () => {
    beforeEach(() => {
      wrapper = createComponent({
        pipelineData: { status: CI_CONFIG_STATUS_VALID, stages: [{ name: 'hello', groups: [] }] },
      });
    });

    it('renders the graph with no status error', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findPipelineGraph().exists()).toBe(true);
    });
  });

  describe('with error while rendering the links with needs', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the error that link could not be drawn', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(wrapper.vm.$options.errorTexts[DRAW_FAILURE]);
    });
  });

  describe('with only one stage', () => {
    beforeEach(() => {
      wrapper = createComponent({ pipelineData: singleStageData });
    });

    it('renders the right number of stage pills', () => {
      const expectedStagesLength = singleStageData.stages.length;

      expect(findAllStagePills()).toHaveLength(expectedStagesLength);
    });

    it('renders the right number of job pills', () => {
      // We count the number of jobs in the mock data
      const expectedJobsLength = singleStageData.stages.reduce((acc, val) => {
        return acc + val.groups.length;
      }, 0);

      expect(findAllJobPills()).toHaveLength(expectedJobsLength);
    });

    describe('rounds corner', () => {
      it.each`
        cssClass                       | expectedState
        ${'gl-rounded-bottom-left-6'}  | ${true}
        ${'gl-rounded-top-left-6'}     | ${true}
        ${'gl-rounded-top-right-6'}    | ${true}
        ${'gl-rounded-bottom-right-6'} | ${true}
      `('$cssClass should be $expectedState on the only element', ({ cssClass, expectedState }) => {
        const classes = findStageBackgroundElementAt(0).classes();

        expect(classes.includes(cssClass)).toBe(expectedState);
      });
    });
  });

  describe('with multiple stages and jobs', () => {
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

    describe('rounds corner', () => {
      it.each`
        cssClass                       | expectedState
        ${'gl-rounded-bottom-left-6'}  | ${true}
        ${'gl-rounded-top-left-6'}     | ${true}
        ${'gl-rounded-top-right-6'}    | ${false}
        ${'gl-rounded-bottom-right-6'} | ${false}
      `(
        '$cssClass should be $expectedState on the first element',
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
      `('$cssClass should be $expectedState on the last element', ({ cssClass, expectedState }) => {
        const classes = findStageBackgroundElementAt(pipelineData.stages.length - 1).classes();

        expect(classes.includes(cssClass)).toBe(expectedState);
      });
    });
  });
});
