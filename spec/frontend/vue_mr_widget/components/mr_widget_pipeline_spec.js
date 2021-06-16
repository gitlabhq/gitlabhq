import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import PipelineStage from '~/pipelines/components/pipelines_list/pipeline_stage.vue';
import PipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import { SUCCESS } from '~/vue_merge_request_widget/constants';
import mockData from '../mock_data';

describe('MRWidgetPipeline', () => {
  let wrapper;

  const defaultProps = {
    pipeline: mockData.pipeline,
    ciStatus: SUCCESS,
    hasCi: true,
    mrTroubleshootingDocsPath: 'help',
    ciTroubleshootingDocsPath: 'ci-help',
  };

  const ciErrorMessage =
    'Could not retrieve the pipeline status. For troubleshooting steps, read the documentation.';
  const monitoringMessage = 'Checking pipeline status.';

  const findCIErrorMessage = () => wrapper.findByTestId('ci-error-message');
  const findPipelineID = () => wrapper.findByTestId('pipeline-id');
  const findPipelineInfoContainer = () => wrapper.findByTestId('pipeline-info-container');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findPipelineFinishedAt = () => wrapper.findByTestId('finished-at');
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findAllPipelineStages = () => wrapper.findAllComponents(PipelineStage);
  const findPipelineCoverage = () => wrapper.findByTestId('pipeline-coverage');
  const findPipelineCoverageDelta = () => wrapper.findByTestId('pipeline-coverage-delta');
  const findPipelineCoverageTooltipText = () =>
    wrapper.findByTestId('pipeline-coverage-tooltip').text();
  const findPipelineCoverageDeltaTooltipText = () =>
    wrapper.findByTestId('pipeline-coverage-delta-tooltip').text();
  const findMonitoringPipelineMessage = () => wrapper.findByTestId('monitoring-pipeline-message');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createWrapper = (props = {}, mountFn = shallowMount) => {
    wrapper = extendedWrapper(
      mountFn(PipelineComponent, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('should render CI error if there is a pipeline, but no status', () => {
    createWrapper({ ciStatus: null }, mount);
    expect(findCIErrorMessage().text()).toBe(ciErrorMessage);
  });

  it('should render a loading state when no pipeline is found', () => {
    createWrapper({ pipeline: {} }, mount);

    expect(findMonitoringPipelineMessage().text()).toBe(monitoringMessage);
    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('with a pipeline', () => {
    beforeEach(() => {
      createWrapper(
        {
          pipelineCoverageDelta: mockData.pipelineCoverageDelta,
          buildsWithCoverage: mockData.buildsWithCoverage,
        },
        mount,
      );
    });

    it('should render pipeline ID', () => {
      expect(findPipelineID().text().trim()).toBe(`#${mockData.pipeline.id}`);
    });

    it('should render pipeline status and commit id', () => {
      expect(findPipelineInfoContainer().text()).toMatch(mockData.pipeline.details.status.label);

      expect(findCommitLink().text().trim()).toBe(mockData.pipeline.commit.short_id);

      expect(findCommitLink().attributes('href')).toBe(mockData.pipeline.commit.commit_path);
    });

    it('should render pipeline finished timestamp', () => {
      expect(findPipelineFinishedAt().attributes()).toMatchObject({
        title: 'Apr 7, 2017 2:00pm UTC',
        datetime: mockData.pipeline.details.finished_at,
      });
    });

    it('should render pipeline graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(true);
      expect(findAllPipelineStages()).toHaveLength(mockData.pipeline.details.stages.length);
    });

    describe('should render pipeline coverage information', () => {
      it('should render coverage percentage', () => {
        expect(findPipelineCoverage().text()).toMatch(
          `Test coverage ${mockData.pipeline.coverage}%`,
        );
      });

      it('should render coverage delta', () => {
        expect(findPipelineCoverageDelta().exists()).toBe(true);
        expect(findPipelineCoverageDelta().text()).toBe(`(${mockData.pipelineCoverageDelta}%)`);
      });

      it('should render tooltip for jobs contributing to code coverage', () => {
        const tooltipText = findPipelineCoverageTooltipText();
        const expectedDescription = `Test coverage value for this pipeline was calculated by averaging the resulting coverage values of ${mockData.buildsWithCoverage.length} jobs.`;

        expect(tooltipText).toContain(expectedDescription);
      });

      it.each(mockData.buildsWithCoverage)(
        'should have name and coverage for build %s listed in tooltip',
        (build) => {
          const tooltipText = findPipelineCoverageTooltipText();

          expect(tooltipText).toContain(`${build.name} (${build.coverage}%)`);
        },
      );

      describe.each`
        style           | coverageState  | coverageChangeText | styleClass        | pipelineCoverageDelta
        ${'no special'} | ${'the same'}  | ${'not change'}    | ${''}             | ${'0'}
        ${'success'}    | ${'increased'} | ${'increase'}      | ${'text-success'} | ${'10'}
        ${'danger'}     | ${'decreased'} | ${'decrease'}      | ${'text-danger'}  | ${'-10'}
      `(
        'if test coverage is $coverageState',
        ({ style, styleClass, coverageChangeText, pipelineCoverageDelta }) => {
          it(`coverage delta should have ${style}`, () => {
            createWrapper({ pipelineCoverageDelta });
            expect(findPipelineCoverageDelta().classes()).toEqual(styleClass ? [styleClass] : []);
          });

          it(`coverage delta tooltip should say that the coverage will ${coverageChangeText}`, () => {
            createWrapper({ pipelineCoverageDelta });
            expect(findPipelineCoverageDeltaTooltipText()).toContain(coverageChangeText);
          });
        },
      );
    });
  });

  describe('without commit path', () => {
    beforeEach(() => {
      const mockCopy = JSON.parse(JSON.stringify(mockData));
      delete mockCopy.pipeline.commit;

      createWrapper({}, mount);
    });

    it('should render pipeline ID', () => {
      expect(findPipelineID().text().trim()).toBe(`#${mockData.pipeline.id}`);
    });

    it('should render pipeline status', () => {
      expect(findPipelineInfoContainer().text()).toMatch(mockData.pipeline.details.status.label);
    });

    it('should render pipeline graph with correct styles', () => {
      const stagesCount = mockData.pipeline.details.stages.length;

      expect(findPipelineMiniGraph().exists()).toBe(true);
      expect(findPipelineMiniGraph().findAll('.mr-widget-pipeline-stages')).toHaveLength(
        stagesCount,
      );

      expect(findAllPipelineStages()).toHaveLength(stagesCount);
    });

    it('should render coverage information', () => {
      expect(findPipelineCoverage().text()).toMatch(`Test coverage ${mockData.pipeline.coverage}%`);
    });
  });

  describe('without coverage', () => {
    beforeEach(() => {
      const mockCopy = JSON.parse(JSON.stringify(mockData));
      delete mockCopy.pipeline.coverage;

      createWrapper({ pipeline: mockCopy.pipeline });
    });

    it('should not render a coverage component', () => {
      expect(findPipelineCoverage().exists()).toBe(false);
    });
  });

  describe('without a pipeline graph', () => {
    beforeEach(() => {
      const mockCopy = JSON.parse(JSON.stringify(mockData));
      delete mockCopy.pipeline.details.stages;

      createWrapper({
        pipeline: mockCopy.pipeline,
      });
    });

    it('should not render a pipeline graph', () => {
      expect(findPipelineMiniGraph().exists()).toBe(false);
    });
  });

  describe('for each type of pipeline', () => {
    let pipeline;

    beforeEach(() => {
      ({ pipeline } = JSON.parse(JSON.stringify(mockData)));

      pipeline.details.name = 'Pipeline';
      pipeline.merge_request_event_type = undefined;
      pipeline.ref.tag = false;
      pipeline.ref.branch = false;
    });

    const factory = () => {
      createWrapper({
        pipeline,
        sourceBranchLink: mockData.source_branch_link,
      });
    };

    describe('for a branch pipeline', () => {
      it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
        pipeline.ref.branch = true;

        factory();

        const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id} on ${mockData.source_branch_link}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });
    });

    describe('for a tag pipeline', () => {
      it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
        pipeline.ref.tag = true;

        factory();

        const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });
    });

    describe('for a detached merge request pipeline', () => {
      it('renders a pipeline widget that reads "Detached merge request pipeline <ID> <status> for <SHA>"', () => {
        pipeline.details.name = 'Detached merge request pipeline';
        pipeline.merge_request_event_type = 'detached';

        factory();

        const expected = `Detached merge request pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });
    });
  });
});
