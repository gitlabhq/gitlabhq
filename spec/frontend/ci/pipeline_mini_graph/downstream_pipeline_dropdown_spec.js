import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import mockDownstreamPipelineJobsQueryResponse from 'test_fixtures/graphql/pipelines/get_downstream_pipeline_jobs.query.graphql.json';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { reportToSentry } from '~/ci/utils';
import { toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';

import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import DownstreamPipelineDropdown from '~/ci/pipeline_mini_graph/downstream_pipeline_dropdown.vue';

import getDownstreamPipelineJobsQuery from '~/ci/pipeline_mini_graph/graphql/queries/get_downstream_pipeline_jobs.query.graphql';
import { singlePipeline } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/ci/utils');
jest.mock('~/ci/pipeline_details/graph/utils');

describe('Downstream Pipeline Dropdown', () => {
  let wrapper;
  let downstreamPipelineJobsResponse;

  const defaultProps = {
    pipeline: singlePipeline,
  };

  const createComponent = ({
    downstreamPipelineJobsHandler = downstreamPipelineJobsResponse,
    props = {},
    mockResponse = false,
    mockError = false,
  } = {}) => {
    if (mockResponse) {
      downstreamPipelineJobsHandler.mockResolvedValue(mockDownstreamPipelineJobsQueryResponse);
    }
    if (mockError) {
      downstreamPipelineJobsHandler.mockRejectedValue(new Error('GraphQL error'));
    }

    const handlers = [[getDownstreamPipelineJobsQuery, downstreamPipelineJobsHandler]];
    const mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(DownstreamPipelineDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findDropdownButton = () => wrapper.findComponent(GlButton);
  const findJobDropdownItems = () => wrapper.findAllComponents(JobDropdownItem);
  const findJobsList = () => wrapper.findByTestId('downstream-jobs-list');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineLink = () => wrapper.find('a');

  const clickStageDropdown = async () => {
    await findDropdownButton().trigger('click');
    await waitForPromises;
  };

  beforeEach(() => {
    downstreamPipelineJobsResponse = jest.fn();
  });

  describe('loading state', () => {
    it('shows loading state while fetching jobs', async () => {
      await createComponent();
      await clickStageDropdown();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findJobsList().exists()).toBe(false);
    });

    it('hides loading state and shows jobs when data is loaded', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findJobsList().exists()).toBe(true);
    });
  });

  describe('graphql query', () => {
    it('passes correct variables to the query', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      expect(downstreamPipelineJobsResponse).toHaveBeenCalledWith({
        iid: singlePipeline.iid,
        fullPath: singlePipeline.project.fullPath,
      });
    });

    it('does not fire query when dropdown is closed', async () => {
      await createComponent();
      await waitForPromises();

      expect(downstreamPipelineJobsResponse).not.toHaveBeenCalled();
    });

    it('does not fire query when project path is not available', async () => {
      await createComponent({
        props: {
          pipeline: {
            ...singlePipeline,
            project: { ...singlePipeline.project, path: '' },
          },
        },
      });
      await waitForPromises();

      expect(downstreamPipelineJobsResponse).not.toHaveBeenCalled();
    });
  });

  describe('dropdown button', () => {
    it('should pass the status to ci icon', () => {
      createComponent();
      expect(findCiIcon().props('status')).toBe(singlePipeline.detailedStatus);

      expect(findCiIcon().props('status')).toEqual(
        expect.objectContaining({
          icon: expect.any(String),
          detailsPath: expect.any(String),
        }),
      );
    });

    it.each`
      scenario                   | pipelineName         | projectName     | expected
      ${'pipeline name'}         | ${'custom-pipeline'} | ${null}         | ${'custom-pipeline - passed'}
      ${'project name fallback'} | ${null}              | ${'my-project'} | ${'my-project - passed'}
      ${'default fallback'}      | ${null}              | ${null}         | ${'Downstream pipeline - passed'}
    `('uses $scenario for title', ({ pipelineName, projectName, expected }) => {
      createComponent({
        props: {
          pipeline: {
            ...singlePipeline,
            name: pipelineName,
            project: { ...singlePipeline.project, name: projectName },
          },
        },
      });

      expect(findDropdownButton().attributes('title')).toBe(expected);
    });
  });

  describe('pipeline link', () => {
    it('renders pipeline ID with correct link', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      const pipelineId = getIdFromGraphQLId(singlePipeline.id);
      expect(findPipelineLink().text()).toBe(`#${pipelineId}`);
      expect(findPipelineLink().attributes('href')).toBe(singlePipeline.path);
    });
  });

  describe('emitters', () => {
    it('emits jobActionExecuted when a job action is triggered', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      findJobDropdownItems().at(0).vm.$emit('jobActionExecuted');
      expect(wrapper.emitted('jobActionExecuted')).toHaveLength(1);
    });
  });

  describe('polling', () => {
    it('initializes polling visibility on mount', async () => {
      await createComponent({ mockResponse: true });
      expect(toggleQueryPollingByVisibility).toHaveBeenCalled();
    });

    it('starts polling when dropdown is open', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      expect(downstreamPipelineJobsResponse).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(8000);

      expect(downstreamPipelineJobsResponse).toHaveBeenCalledTimes(2);
    });

    it('stops polling when dropdown is closed', async () => {
      await createComponent({ mockResponse: true });
      await clickStageDropdown();
      await waitForPromises();

      expect(downstreamPipelineJobsResponse).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(8000);
      expect(downstreamPipelineJobsResponse).toHaveBeenCalledTimes(2);

      await clickStageDropdown();
      await waitForPromises();

      jest.advanceTimersByTime(8000);
      expect(downstreamPipelineJobsResponse).toHaveBeenCalledTimes(2);
    });
  });

  describe('error handling', () => {
    it('shows error alert and reports to sentry when query fails', async () => {
      await createComponent({ mockError: true });
      await clickStageDropdown();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the downstream pipeline jobs.',
      });
      expect(reportToSentry).toHaveBeenCalledWith('DownstreamPipelineDropdown', expect.any(Error));
    });
  });
});
