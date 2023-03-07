import { GlButton, GlLink, GlTableLite } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility';
import FailedJobsTable from '~/pipelines/components/jobs/failed_jobs_table.vue';
import RetryFailedJobMutation from '~/pipelines/graphql/mutations/retry_failed_job.mutation.graphql';
import {
  successRetryMutationResponse,
  failedRetryMutationResponse,
  mockPreparedFailedJobsData,
  mockPreparedFailedJobsDataNoPermission,
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

  const createMockApolloProvider = (resolver) => {
    const requestHandlers = [[RetryFailedJobMutation, resolver]];
    return createMockApollo(requestHandlers);
  };

  const createComponent = (resolver, failedJobsData = mockPreparedFailedJobsData) => {
    wrapper = mountExtended(FailedJobsTable, {
      propsData: {
        failedJobs: failedJobsData,
      },
      apolloProvider: createMockApolloProvider(resolver),
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the failed jobs table', () => {
    createComponent();

    expect(findJobsTable().exists()).toBe(true);
  });

  it('calls the retry failed job mutation correctly', () => {
    createComponent(successRetryMutationHandler);

    findRetryButton().trigger('click');

    expect(successRetryMutationHandler).toHaveBeenCalledWith({
      id: mockPreparedFailedJobsData[0].id,
    });
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

    expect(redirectTo).toHaveBeenCalledWith(job.detailedStatus.detailsPath);
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
    createComponent([[]], mockPreparedFailedJobsDataNoPermission);

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

    expect(findJobLink().attributes('href')).toBe(
      mockPreparedFailedJobsData[0].detailedStatus.detailsPath,
    );
  });
});
