import Vue, { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import MRWidgetPipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  SUCCESS,
  PIPELINE_EVENT_TYPE_MERGE_TRAIN,
  PIPELINE_EVENT_TYPE_MERGED_RESULT,
  PIPELINE_EVENT_TYPE_MERGE_REQUEST,
  PIPELINE_EVENT_TYPE_MAP,
} from '~/vue_merge_request_widget/constants';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import mergeRequestEventTypeQuery from '~/vue_merge_request_widget/queries/merge_request_event_type.query.graphql';
import mockData from '../mock_data';

jest.mock('~/alert');
jest.mock('~/api');

Vue.use(VueApollo);

describe('MRWidgetPipeline', () => {
  let wrapper;
  let mergeRequestEventTypeQueryMock;

  const defaultProps = {
    pipeline: mockData.pipeline,
    pipelineEtag: '/api/graphql:pipelines/sha/a3cf305c10be3fafdd89b12cb1c389e6bde45875',
    pipelineMiniGraphVariables: {
      iid: '12',
      fullPath: 'project/path',
    },
    ciStatus: SUCCESS,
    hasCi: true,
    mrTroubleshootingDocsPath: 'help',
    ciTroubleshootingDocsPath: 'ci-help',
    targetProjectId: 1,
    iid: 1,
    targetProjectFullPath: 'gitlab-org/gitlab',
  };

  const ciErrorMessage =
    'Could not retrieve the pipeline status. For troubleshooting steps, read the documentation.';
  const monitoringMessage = 'Checking pipeline status.';

  const findCIErrorMessage = () => wrapper.findByTestId('ci-error-message');
  const findPipelineID = () => wrapper.findByTestId('pipeline-id');
  const findPipelineInfoContainer = () => wrapper.findByTestId('pipeline-info-container');
  const findPipelineDetailsContainer = () => wrapper.findByTestId('pipeline-details-container');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findPipelineFinishedAt = () => wrapper.findByTestId('finished-at');
  const findPipelineCoverage = () => wrapper.findByTestId('pipeline-coverage');
  const findPipelineCoverageDelta = () => wrapper.findByTestId('pipeline-coverage-delta');
  const findPipelineCoverageTooltipText = () =>
    wrapper.findByTestId('pipeline-coverage-tooltip').text();
  const findPipelineCoverageDeltaTooltipText = () =>
    wrapper.findByTestId('pipeline-coverage-delta-tooltip').text();
  const findPipelineMiniGraph = () => wrapper.findComponent(PipelineMiniGraph);
  const findMonitoringPipelineMessage = () => wrapper.findByTestId('monitoring-pipeline-message');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findRetargetedMessage = () => wrapper.findByTestId('retargeted-message');
  const findRunPipelineButton = () => wrapper.findByTestId('run-pipeline-button');
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);

  const mockArtifactsRequest = () => new MockAdapter(axios).onGet().reply(HTTP_STATUS_OK, []);

  const createWrapper = (props = {}, mountFn = shallowMount) => {
    const apolloProvider = createMockApollo([
      [mergeRequestEventTypeQuery, mergeRequestEventTypeQueryMock],
    ]);

    wrapper = extendedWrapper(
      mountFn(MRWidgetPipelineComponent, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        apolloProvider,
      }),
    );
  };

  afterEach(() => {
    mergeRequestEventTypeQueryMock = null;
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
      mockArtifactsRequest();

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
        title: localeDateFormat.asDateTimeFull.format(mockData.pipeline.details.finished_at),
        datetime: mockData.pipeline.details.finished_at,
      });
    });

    it('should render pipeline graph', () => {
      const stagesCount = mockData.pipeline.details.stages.length;

      expect(findPipelineMiniGraph().exists()).toBe(true);
      expect(findPipelineMiniGraph().props('pipelineStages')).toHaveLength(stagesCount);
    });

    it('should render the latest downstream pipelines only', () => {
      // component receives two downstream pipelines. one of them is already outdated
      // because we retried the trigger job, so the mini pipeline graph will only
      // render the newly created downstream pipeline instead
      expect(mockData.pipeline.triggered).toHaveLength(2);
      expect(findPipelineMiniGraph().props('downstreamPipelines')).toHaveLength(1);
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
        style           | coverageState  | coverageChangeText | styleClass           | pipelineCoverageDelta
        ${'no special'} | ${'the same'}  | ${'not change'}    | ${''}                | ${'0'}
        ${'success'}    | ${'increased'} | ${'increase'}      | ${'gl-text-success'} | ${'10'}
        ${'danger'}     | ${'decreased'} | ${'decrease'}      | ${'gl-text-danger'}  | ${'-10'}
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

    it('should render pipeline graph', () => {
      const stagesCount = mockData.pipeline.details.stages.length;

      expect(findPipelineMiniGraph().exists()).toBe(true);
      expect(findPipelineMiniGraph().props('pipelineStages')).toHaveLength(stagesCount);
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

      pipeline.details.event_type_name = 'Pipeline';
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
      it('renders a pipeline widget that reads "Pipeline <ID> <status>"', () => {
        pipeline.ref.branch = true;

        factory();

        const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });

      it('renders a pipeline widget that reads "Pipeline <status> for <SHA> on <branch>"', () => {
        pipeline.ref.branch = true;

        factory();

        const expected = `Pipeline ${pipeline.details.status.label} for ${pipeline.commit.short_id} on ${mockData.source_branch_link}`;
        const actual = trimText(findPipelineDetailsContainer().text());

        expect(actual).toBe(expected);
      });
    });

    describe('for a tag pipeline', () => {
      it('renders a pipeline widget that reads "Pipeline <ID> <status>"', () => {
        pipeline.ref.tag = true;

        factory();

        const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });

      it('renders a pipeline widget that reads "Pipeline <status> for <SHA> on <branch>"', () => {
        pipeline.ref.tag = true;

        factory();

        const expected = `Pipeline ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(findPipelineDetailsContainer().text());

        expect(actual).toBe(expected);
      });
    });

    describe('for a detached merge request pipeline', () => {
      it('renders a pipeline widget that reads "Merge request pipeline <ID> <status>"', () => {
        pipeline.details.event_type_name = 'Merge request pipeline';
        pipeline.merge_request_event_type = 'detached';

        factory();

        const expected = `Merge request pipeline #${pipeline.id} ${pipeline.details.status.label}`;
        const actual = trimText(findPipelineInfoContainer().text());

        expect(actual).toBe(expected);
      });

      it('renders a pipeline widget that reads "Merge request pipeline <status> for <SHA>"', () => {
        pipeline.details.event_type_name = 'Merge request pipeline';
        pipeline.merge_request_event_type = 'detached';

        factory();

        const expected = `Merge request pipeline ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
        const actual = trimText(findPipelineDetailsContainer().text());

        expect(actual).toBe(expected);
      });
    });

    describe('rendering help popover for a specific event types', () => {
      it.each([
        {
          eventType: PIPELINE_EVENT_TYPE_MERGE_TRAIN,
          expectedOptions: PIPELINE_EVENT_TYPE_MAP[PIPELINE_EVENT_TYPE_MERGE_TRAIN],
        },
        {
          eventType: PIPELINE_EVENT_TYPE_MERGED_RESULT,
          expectedOptions: PIPELINE_EVENT_TYPE_MAP[PIPELINE_EVENT_TYPE_MERGED_RESULT],
        },
        {
          eventType: PIPELINE_EVENT_TYPE_MERGE_REQUEST,
          expectedOptions: PIPELINE_EVENT_TYPE_MAP[PIPELINE_EVENT_TYPE_MERGE_REQUEST],
        },
      ])(
        'renders help popover with options relevant to "$eventType" event type',
        ({ eventType, expectedOptions }) => {
          pipeline.details.event_type_name = eventType;

          factory();

          expect(findHelpPopover().props().options).toMatchObject(expectedOptions);
        },
      );

      it('does not render a help popover for unknown event type', () => {
        pipeline.details.event_type_name = 'unknown';

        factory();

        expect(findHelpPopover().exists()).toBe(false);
      });
    });
  });

  describe('when merge request is retargeted', () => {
    describe('when last pipeline is detatched', () => {
      beforeEach(async () => {
        mergeRequestEventTypeQueryMock = jest.fn().mockResolvedValue({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                pipelines: { nodes: [{ id: 1, mergeRequestEventType: 'DETACHED' }] },
              },
            },
          },
        });

        createWrapper({
          retargeted: true,
        });

        await waitForPromises();
      });

      it('renders branch changed message', () => {
        expect(findRetargetedMessage().text()).toBe(
          'You should run a new pipeline, because the target branch has changed for this merge request.',
        );
      });

      it('render run pipeline button', () => {
        expect(findRunPipelineButton().exists()).toBe(true);
      });

      it('calls postMergeRequestPipeline API method', async () => {
        findRunPipelineButton().vm.$emit('click');

        await nextTick();

        expect(findRunPipelineButton().props('loading')).toBe(true);
        expect(Api.postMergeRequestPipeline).toHaveBeenCalledWith(1, { mergeRequestId: 1 });
      });

      describe('when API call fails', () => {
        describe('when user has permission to create a pipeline', () => {
          beforeEach(() => {
            Api.postMergeRequestPipeline.mockRejectedValue({
              response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR },
            });
          });

          it('returns loading state on button to default state', async () => {
            findRunPipelineButton().vm.$emit('click');

            await waitForPromises();

            expect(findRunPipelineButton().props('loading')).toBe(false);
          });

          it('creates a new alert', async () => {
            findRunPipelineButton().vm.$emit('click');

            await waitForPromises();

            expect(createAlert).toHaveBeenCalledWith({
              message:
                'An error occurred while trying to run a new pipeline for this merge request.',
              primaryButton: {
                link: '/help/ci/pipelines/merge_request_pipelines.md',
                text: 'Learn more',
              },
            });
          });
        });

        describe('when user does not have permission to create a pipeline', () => {
          beforeEach(() => {
            Api.postMergeRequestPipeline.mockRejectedValue({
              response: { status: HTTP_STATUS_UNAUTHORIZED },
            });
          });

          it('creates a new alert', async () => {
            findRunPipelineButton().vm.$emit('click');

            await waitForPromises();

            expect(createAlert).toHaveBeenCalledWith({
              message: 'You do not have permission to run a pipeline on this branch.',
              primaryButton: {
                link: '/help/ci/pipelines/merge_request_pipelines.md',
                text: 'Learn more',
              },
            });
          });
        });
      });
    });

    describe('when last pipeline is a branch pipeline', () => {
      beforeEach(async () => {
        mergeRequestEventTypeQueryMock = jest.fn().mockResolvedValue({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                pipelines: { nodes: [{ id: 1, mergeRequestEventType: null }] },
              },
            },
          },
        });

        createWrapper({
          retargeted: true,
        });

        await waitForPromises();
      });

      it('renders branch changed message', () => {
        expect(findRetargetedMessage().text()).toBe(
          'You should run a new pipeline, because the target branch has changed for this merge request.',
        );
      });

      it('does not render the run pipeline button', () => {
        expect(findRunPipelineButton().exists()).toBe(false);
      });
    });
  });
});
