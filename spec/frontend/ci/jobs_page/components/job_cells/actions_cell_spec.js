import { GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import ActionsCell from '~/ci/jobs_page/components/job_cells/actions_cell.vue';
import eventHub from '~/ci/jobs_page/event_hub';
import JobPlayMutation from '~/ci/jobs_page/graphql/mutations/job_play.mutation.graphql';
import JobRetryMutation from '~/ci/jobs_page/graphql/mutations/job_retry.mutation.graphql';
import JobUnscheduleMutation from '~/ci/jobs_page/graphql/mutations/job_unschedule.mutation.graphql';
import JobCancelMutation from '~/ci/jobs_page/graphql/mutations/job_cancel.mutation.graphql';
import {
  mockJobsNodes,
  mockJobsNodesAsGuest,
  playMutationResponse,
  retryMutationResponse,
  unscheduleMutationResponse,
  cancelMutationResponse,
} from 'jest/ci/jobs_mock_data';

jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

describe('Job actions cell', () => {
  let wrapper;

  const findMockJob = (jobName, nodes = mockJobsNodes) => {
    const job = nodes.find(({ name }) => name === jobName);
    expect(job).toBeDefined(); // ensure job is present
    return job;
  };

  const mockJob = findMockJob('build');
  const cancelableJob = findMockJob('cancelable');
  const playableJob = findMockJob('playable');
  const retryableJob = findMockJob('retryable');
  const failedJob = findMockJob('failed');
  const scheduledJob = findMockJob('scheduled');
  const jobWithArtifact = findMockJob('with_artifact');
  const cannotPlayJob = findMockJob('playable', mockJobsNodesAsGuest);
  const cannotRetryJob = findMockJob('retryable', mockJobsNodesAsGuest);
  const cannotPlayScheduledJob = findMockJob('scheduled', mockJobsNodesAsGuest);
  const cannotCancelJob = findMockJob('cancelable', mockJobsNodesAsGuest);

  const findRetryButton = () => wrapper.findByTestId('retry');
  const findPlayButton = () => wrapper.findByTestId('play');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findDownloadArtifactsButton = () => wrapper.findByTestId('download-artifacts');
  const findCountdownButton = () => wrapper.findByTestId('countdown');
  const findPlayScheduledJobButton = () => wrapper.findByTestId('play-scheduled');
  const findUnscheduleButton = () => wrapper.findByTestId('unschedule');

  const findModal = () => wrapper.findComponent(GlModal);

  const playMutationHandler = jest.fn().mockResolvedValue(playMutationResponse);
  const retryMutationHandler = jest.fn().mockResolvedValue(retryMutationResponse);
  const unscheduleMutationHandler = jest.fn().mockResolvedValue(unscheduleMutationResponse);
  const cancelMutationHandler = jest.fn().mockResolvedValue(cancelMutationResponse);

  const $toast = {
    show: jest.fn(),
  };

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (job, requestHandlers, props = {}) => {
    wrapper = shallowMountExtended(ActionsCell, {
      propsData: {
        job,
        ...props,
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
      mocks: {
        $toast,
      },
    });
  };

  it('displays the artifacts download button with correct link', () => {
    createComponent(jobWithArtifact);

    expect(findDownloadArtifactsButton().attributes('href')).toBe(
      jobWithArtifact.artifacts.nodes[0].downloadPath,
    );
  });

  it('does not display an artifacts download button', () => {
    createComponent(mockJob);

    expect(findDownloadArtifactsButton().exists()).toBe(false);
  });

  it.each`
    button                        | action              | jobType
    ${findPlayButton}             | ${'play'}           | ${cannotPlayJob}
    ${findRetryButton}            | ${'retry'}          | ${cannotRetryJob}
    ${findPlayScheduledJobButton} | ${'play scheduled'} | ${cannotPlayScheduledJob}
    ${findCancelButton}           | ${'cancel'}         | ${cannotCancelJob}
  `('does not display the $action button if user cannot update build', ({ button, jobType }) => {
    createComponent(jobType);

    expect(button().exists()).toBe(false);
  });

  it.each`
    button                         | action                  | jobType
    ${findPlayButton}              | ${'play'}               | ${playableJob}
    ${findRetryButton}             | ${'retry'}              | ${retryableJob}
    ${findDownloadArtifactsButton} | ${'download artifacts'} | ${jobWithArtifact}
    ${findCancelButton}            | ${'cancel'}             | ${cancelableJob}
  `('displays the $action button', ({ button, jobType }) => {
    createComponent(jobType);

    expect(button().exists()).toBe(true);
  });

  it.each`
    button              | action      | jobType          | mutationFile         | handler                  | jobId
    ${findPlayButton}   | ${'play'}   | ${playableJob}   | ${JobPlayMutation}   | ${playMutationHandler}   | ${playableJob.id}
    ${findRetryButton}  | ${'retry'}  | ${retryableJob}  | ${JobRetryMutation}  | ${retryMutationHandler}  | ${retryableJob.id}
    ${findCancelButton} | ${'cancel'} | ${cancelableJob} | ${JobCancelMutation} | ${cancelMutationHandler} | ${cancelableJob.id}
  `('performs the $action mutation', ({ button, jobType, mutationFile, handler, jobId }) => {
    createComponent(jobType, [[mutationFile, handler]]);

    button().vm.$emit('click');

    expect(handler).toHaveBeenCalledWith({ id: jobId });
  });

  it.each`
    button                  | action          | jobType          | mutationFile             | handler
    ${findUnscheduleButton} | ${'unschedule'} | ${scheduledJob}  | ${JobUnscheduleMutation} | ${unscheduleMutationHandler}
    ${findCancelButton}     | ${'cancel'}     | ${cancelableJob} | ${JobCancelMutation}     | ${cancelMutationHandler}
  `(
    'the mutation action $action emits the jobActionPerformed event',
    async ({ button, jobType, mutationFile, handler }) => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

      createComponent(jobType, [[mutationFile, handler]]);

      button().vm.$emit('click');

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith('jobActionPerformed');
      expect(redirectTo).not.toHaveBeenCalled(); // eslint-disable-line import/no-deprecated
    },
  );

  it.each`
    button             | action     | jobType         | mutationFile        | handler                 | redirectLink
    ${findPlayButton}  | ${'play'}  | ${playableJob}  | ${JobPlayMutation}  | ${playMutationHandler}  | ${'/root/project/-/jobs/1986'}
    ${findRetryButton} | ${'retry'} | ${retryableJob} | ${JobRetryMutation} | ${retryMutationHandler} | ${'/root/project/-/jobs/1985'}
  `(
    'the mutation action $action redirects to the job',
    async ({ button, jobType, mutationFile, handler, redirectLink }) => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

      createComponent(jobType, [[mutationFile, handler]]);

      button().vm.$emit('click');

      await waitForPromises();

      expect(redirectTo).toHaveBeenCalledWith(redirectLink); // eslint-disable-line import/no-deprecated
      expect(eventHub.$emit).not.toHaveBeenCalled();
    },
  );

  it.each`
    button                  | action          | jobType
    ${findPlayButton}       | ${'play'}       | ${playableJob}
    ${findRetryButton}      | ${'retry'}      | ${retryableJob}
    ${findCancelButton}     | ${'cancel'}     | ${cancelableJob}
    ${findUnscheduleButton} | ${'unschedule'} | ${scheduledJob}
  `('disables the $action button after first request', async ({ button, jobType }) => {
    createComponent(jobType);

    expect(button().props('disabled')).toBe(false);

    button().vm.$emit('click');

    await waitForPromises();

    expect(button().props('disabled')).toBe(true);
  });

  describe('Retry button title', () => {
    it('displays retry title when job has failed and is retryable', () => {
      createComponent(failedJob);

      expect(findRetryButton().attributes('title')).toBe('Retry');
    });

    it('displays run again title when job has passed and is retryable', () => {
      createComponent(retryableJob);

      expect(findRetryButton().attributes('title')).toBe('Run again');
    });
  });

  describe('Scheduled Jobs', () => {
    const today = () => new Date('2021-08-31');

    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(today);
    });

    it('displays the countdown, play and unschedule buttons', () => {
      createComponent(scheduledJob);

      expect(findCountdownButton().exists()).toBe(true);
      expect(findPlayScheduledJobButton().exists()).toBe(true);
      expect(findUnscheduleButton().exists()).toBe(true);
    });

    it('unschedules a job', () => {
      createComponent(scheduledJob, [[JobUnscheduleMutation, unscheduleMutationHandler]]);

      findUnscheduleButton().vm.$emit('click');

      expect(unscheduleMutationHandler).toHaveBeenCalledWith({
        id: scheduledJob.id,
      });
    });

    it('shows the play job confirmation modal', async () => {
      createComponent(scheduledJob);

      findPlayScheduledJobButton().vm.$emit('click');

      await nextTick();

      expect(findModal().exists()).toBe(true);
    });
  });
});
