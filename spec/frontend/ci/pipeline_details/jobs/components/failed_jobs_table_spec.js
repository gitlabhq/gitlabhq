import { GlButton, GlLink, GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import FailedJobsTable from '~/ci/pipeline_details/jobs/components/failed_jobs_table.vue';
import RetryFailedJobMutation from '~/ci/pipeline_details/jobs/graphql/mutations/retry_failed_job.mutation.graphql';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import {
  successRetryMutationResponse,
  failedRetryMutationResponse,
  mockFailedJobsData,
  mockFailedJobsDataNoPermission,
} from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

describe('Failed Jobs Table', () => {
  let wrapper;

  const successRetryMutationHandler = jest.fn().mockResolvedValue(successRetryMutationResponse);
  const failedRetryMutationHandler = jest.fn().mockResolvedValue(failedRetryMutationResponse);

  const findJobsTable = () => wrapper.findComponent(GlTableLite);
  const findRetryButton = () => wrapper.findComponent(GlButton);
  const findJobLink = () => wrapper.findComponent(GlLink);
  const findJobLog = () => wrapper.findByTestId('job-log');
  const findSummary = (index) => wrapper.findAllByTestId('job-trace-summary').at(index);
  const findFirstFailureMessage = () => wrapper.findAllByTestId('job-failure-message').at(0);

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[RetryFailedJobMutation, resolver]];
    return createMockApollo(requestHandlers);
  };

  const createComponent = (resolver, failedJobsData = mockFailedJobsData) => {
    wrapper = mountExtended(FailedJobsTable, {
      propsData: {
        failedJobs: failedJobsData,
      },
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  it('displays the failed jobs table', () => {
    createComponent();

    expect(findJobsTable().exists()).toBe(true);
  });

  it('displays failed job summary', () => {
    createComponent();

    expect(findSummary(0).text()).toBe('Html Summary');
  });

  it('displays no job log when no trace', () => {
    createComponent();

    expect(findSummary(1).text()).toBe('No job log');
  });

  it('displays failure reason', () => {
    createComponent();

    expect(findFirstFailureMessage().text()).toBe('Job failed');
  });

  it('calls the retry failed job mutation and tracks the click', () => {
    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

    createComponent(successRetryMutationHandler);

    findRetryButton().trigger('click');

    expect(successRetryMutationHandler).toHaveBeenCalledWith({
      id: mockFailedJobsData[0].id,
    });
    expect(trackingSpy).toHaveBeenCalledTimes(1);
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_retry', {
      label: TRACKING_CATEGORIES.failed,
    });

    unmockTracking();
  });

  it('redirects to the new job after the mutation', async () => {
    const {
      data: {
        jobRetry: { job },
      },
    } = successRetryMutationResponse;

    createComponent(successRetryMutationHandler);

    findRetryButton().trigger('click');

    await waitForPromises();

    expect(visitUrl).toHaveBeenCalledWith(job.detailedStatus.detailsPath);
  });

  it('shows error message if the retry failed job mutation fails', async () => {
    createComponent(failedRetryMutationHandler);

    findRetryButton().trigger('click');

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'There was a problem retrying the failed job.',
    });
  });

  it('hides the job log and retry button if a user does not have permission', () => {
    createComponent([[]], mockFailedJobsDataNoPermission);

    expect(findJobLog().exists()).toBe(false);
    expect(findRetryButton().exists()).toBe(false);
  });

  it('displays the job log and retry button if a user has permission', () => {
    createComponent();

    expect(findJobLog().exists()).toBe(true);
    expect(findRetryButton().exists()).toBe(true);
  });

  it('job name links to the correct job', () => {
    createComponent();

    expect(findJobLink().attributes('href')).toBe(mockFailedJobsData[0].detailedStatus.detailsPath);
  });
});
