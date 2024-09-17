import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { GlAlert, GlLoadingIcon, GlToast } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import FailedJobsList from '~/ci/pipelines_page/components/failure_widget/failed_jobs_list.vue';
import FailedJobDetails from '~/ci/pipelines_page/components/failure_widget/failed_job_details.vue';
import * as utils from '~/ci/pipelines_page/components/failure_widget/utils';
import getPipelineFailedJobs from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs.query.graphql';
import { failedJobsMock, failedJobsMock2, failedJobsMockEmpty, activeFailedJobsMock } from './mock';

Vue.use(VueApollo);
Vue.use(GlToast);

jest.mock('~/alert');

describe('FailedJobsList component', () => {
  let wrapper;
  let mockFailedJobsResponse;
  const showToast = jest.fn();

  const defaultProps = {
    failedJobsCount: 0,
    graphqlResourceEtag: 'api/graphql',
    isMaximumJobLimitReached: false,
    isPipelineActive: false,
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

    it('does not renders a loading icon', () => {
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
    it.each`
      isGraphqlActive | text
      ${true}         | ${'polls'}
      ${false}        | ${'does not poll'}
    `(`$text when isGraphqlActive: $isGraphqlActive`, async ({ isGraphqlActive }) => {
      const defaultCount = 2;
      const newCount = 1;

      const expectedCount = isGraphqlActive ? newCount : defaultCount;
      const expectedCallCount = isGraphqlActive ? 2 : 1;
      const mockResponse = isGraphqlActive ? activeFailedJobsMock : failedJobsMock;

      // Second result is to simulate polling with a different response
      mockFailedJobsResponse.mockResolvedValueOnce(mockResponse);
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock2);

      createComponent();
      await waitForPromises();

      // Initially, we get the first response which is always the default
      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      expect(findFailedJobRows()).toHaveLength(defaultCount);

      jest.advanceTimersByTime(10000);
      await waitForPromises();

      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(expectedCallCount);
      expect(findFailedJobRows()).toHaveLength(expectedCount);
    });
  });

  describe('when a REST action occurs', () => {
    beforeEach(() => {
      // Second result is to simulate polling with a different response
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock);
      mockFailedJobsResponse.mockResolvedValueOnce(failedJobsMock2);
    });

    it.each([true, false])('triggers a refetch of the jobs count', async (isPipelineActive) => {
      const defaultCount = 2;
      const newCount = 1;

      createComponent({ props: { isPipelineActive } });
      await waitForPromises();

      // Initially, we get the first response which is always the default
      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      expect(findFailedJobRows()).toHaveLength(defaultCount);

      wrapper.setProps({ isPipelineActive: !isPipelineActive });
      await waitForPromises();

      expect(mockFailedJobsResponse).toHaveBeenCalledTimes(2);
      expect(findFailedJobRows()).toHaveLength(newCount);
    });
  });

  describe('When the job count changes from REST', () => {
    beforeEach(() => {
      mockFailedJobsResponse.mockResolvedValue(failedJobsMockEmpty);

      createComponent();
    });

    describe('and the count is the same', () => {
      it('does not re-fetch the query', async () => {
        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);

        await wrapper.setProps({ failedJobsCount: 0 });

        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);
      });
    });

    describe('and the count is different', () => {
      it('re-fetches the query', async () => {
        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(1);

        await wrapper.setProps({ failedJobsCount: 10 });

        expect(mockFailedJobsResponse).toHaveBeenCalledTimes(2);
      });
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

    it('refetches all failed jobs', async () => {
      expect(findFailedJobRows()).not.toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );

      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(findFailedJobRows()).toHaveLength(
        failedJobsMock2.data.project.pipeline.jobs.nodes.length,
      );
    });

    it('shows a toast message', async () => {
      await findFailedJobRows().at(0).vm.$emit('job-retried', 'job-name');
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('job-name job is being retried');
    });
  });
});
