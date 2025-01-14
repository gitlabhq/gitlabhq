import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { GlAlert, GlLoadingIcon, GlToast } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { toggleQueryPollingByVisibility } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import FailedJobsList from '~/ci/pipelines_page/components/failure_widget/failed_jobs_list.vue';
import FailedJobDetails from '~/ci/pipelines_page/components/failure_widget/failed_job_details.vue';
import * as utils from '~/ci/pipelines_page/components/failure_widget/utils';
import getPipelineFailedJobs from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs.query.graphql';
import { failedJobsMock, failedJobsMock2 } from './mock';

Vue.use(VueApollo);
Vue.use(GlToast);

jest.mock('~/alert');
jest.mock('~/graphql_shared/utils');

describe('FailedJobsList component', () => {
  let wrapper;
  let mockFailedJobsResponse;
  const showToast = jest.fn();

  const defaultProps = {
    graphqlResourceEtag: 'api/graphql',
    isMaximumJobLimitReached: false,
    pipelineIid: 1,
    pipelinePath: 'namespace/project/pipeline',
    projectPath: 'namespace/project/',
  };

  const defaultProvide = {
    graphqlPath: 'api/graphql',
  };

  const createComponent = ({ props = {}, provide } = {}) => {
    const handlers = [[getPipelineFailedJobs, mockFailedJobsResponse]];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(FailedJobsList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      apolloProvider: mockApollo,
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const findAllHeaders = () => wrapper.findAllByTestId('header');
  const findFailedJobRows = () => wrapper.findAllComponents(FailedJobDetails);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMaximumJobLimitAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    mockFailedJobsResponse = jest.fn();
  });

  describe('on mount', () => {
    beforeEach(() => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMock);
      createComponent();
    });

    it('fires the graphql query', () => {
      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      expect(mockFailedJobsResponse).toHaveBeenCalledWith({
        fullPath: defaultProps.projectPath,
        pipelineIid: defaultProps.pipelineIid,
      });
    });
  });

  describe('when loading failed jobs', () => {
    beforeEach(() => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMock);
      createComponent();
    });

    it('shows a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when failed jobs have loaded', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMock);
      jest.spyOn(utils, 'sortJobsByStatus');

      createComponent();

      await waitForPromises();
    });

    it('does not render a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders table column', () => {
      expect(findAllHeaders()).toHaveLength(3);
    });

    it('shows the list of failed jobs', () => {
      expect(findFailedJobRows()).toHaveLength(
        failedJobsMock.data.project.pipeline.jobs.nodes.length,
      );
    });

    it('passes the correct props to failed jobs row', () => {
      expect(findFailedJobRows().at(0).props()).toStrictEqual({
        canTroubleshootJob: true,
        job: failedJobsMock.data.project.pipeline.jobs.nodes[0],
      });
    });

    it('calls sortJobsByStatus', () => {
      expect(utils.sortJobsByStatus).toHaveBeenCalledWith(
        failedJobsMock.data.project.pipeline.jobs.nodes,
      );
    });

    describe('and the maximum failed job limit is reached', () => {
      beforeEach(async () => {
        createComponent({ props: { isMaximumJobLimitReached: true } });
        await waitForPromises();
      });

      it('displays the alert', () => {
        expect(findMaximumJobLimitAlert().exists()).toBe(true);
      });
    });
  });

  describe('polling', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock);
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock2);

      createComponent();

      await waitForPromises();
    });
    it('polls for failed jobs', async () => {
      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      expect(findFailedJobRows()).toHaveLength(2);

      jest.advanceTimersByTime(10000);

      await waitForPromises();

      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(2);
      expect(findFailedJobRows()).toHaveLength(1);
    });

    it('should set up toggle visibility on mount', () => {
      expect(toggleQueryPollingByVisibility).toHaveBeenCalled();
    });
  });

  describe('when an error occurs loading jobs', () => {
    const errorMessage = "We couldn't fetch jobs for you because you are not qualified";

    beforeEach(async () => {
      mockFailedJobsResponse.mockRejectedValue({ message: errorMessage });

      createComponent();

      await waitForPromises();
    });
    it('does not renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('calls create Alert with the error message and danger variant', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
    });
  });

  describe('when `refetch-jobs` job is fired from the widget', () => {
    beforeEach(async () => {
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock);
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock2);

      createComponent();

      await waitForPromises();
    });

    it('refetches all failed jobs and emits event', async () => {
      expect(findFailedJobRows()).not.toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );

      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(findFailedJobRows()).toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );
      expect(wrapper.emitted()).toEqual({ 'job-retried': [[]] });
    });

    it('shows a toast message', async () => {
      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('job-name job is being retried');
    });
  });
});
