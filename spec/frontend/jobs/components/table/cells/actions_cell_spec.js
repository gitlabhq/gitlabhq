import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActionsCell from '~/jobs/components/table/cells/actions_cell.vue';
import JobPlayMutation from '~/jobs/components/table/graphql/mutations/job_play.mutation.graphql';
import JobRetryMutation from '~/jobs/components/table/graphql/mutations/job_retry.mutation.graphql';
import JobUnscheduleMutation from '~/jobs/components/table/graphql/mutations/job_unschedule.mutation.graphql';
import JobCancelMutation from '~/jobs/components/table/graphql/mutations/job_cancel.mutation.graphql';
import {
  playableJob,
  retryableJob,
  cancelableJob,
  scheduledJob,
  cannotRetryJob,
  cannotPlayJob,
  cannotPlayScheduledJob,
} from '../../../mock_data';

describe('Job actions cell', () => {
  let wrapper;
  let mutate;

  const findRetryButton = () => wrapper.findByTestId('retry');
  const findPlayButton = () => wrapper.findByTestId('play');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findDownloadArtifactsButton = () => wrapper.findByTestId('download-artifacts');
  const findCountdownButton = () => wrapper.findByTestId('countdown');
  const findPlayScheduledJobButton = () => wrapper.findByTestId('play-scheduled');
  const findUnscheduleButton = () => wrapper.findByTestId('unschedule');

  const findModal = () => wrapper.findComponent(GlModal);

  const MUTATION_SUCCESS = { data: { JobRetryMutation: { jobId: retryableJob.id } } };
  const MUTATION_SUCCESS_UNSCHEDULE = {
    data: { JobUnscheduleMutation: { jobId: scheduledJob.id } },
  };
  const MUTATION_SUCCESS_PLAY = { data: { JobPlayMutation: { jobId: playableJob.id } } };
  const MUTATION_SUCCESS_CANCEL = { data: { JobCancelMutation: { jobId: cancelableJob.id } } };

  const $toast = {
    show: jest.fn(),
  };

  const createComponent = (jobType, mutationType = MUTATION_SUCCESS, props = {}) => {
    mutate = jest.fn().mockResolvedValue(mutationType);

    wrapper = shallowMountExtended(ActionsCell, {
      propsData: {
        job: jobType,
        ...props,
      },
      mocks: {
        $apollo: {
          mutate,
        },
        $toast,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the artifacts download button with correct link', () => {
    createComponent(playableJob);

    expect(findDownloadArtifactsButton().attributes('href')).toBe(
      playableJob.artifacts.nodes[0].downloadPath,
    );
  });

  it('does not display an artifacts download button', () => {
    createComponent(retryableJob);

    expect(findDownloadArtifactsButton().exists()).toBe(false);
  });

  it.each`
    button                        | action              | jobType
    ${findPlayButton}             | ${'play'}           | ${cannotPlayJob}
    ${findRetryButton}            | ${'retry'}          | ${cannotRetryJob}
    ${findPlayScheduledJobButton} | ${'play scheduled'} | ${cannotPlayScheduledJob}
  `('does not display the $action button if user cannot update build', ({ button, jobType }) => {
    createComponent(jobType);

    expect(button().exists()).toBe(false);
  });

  it.each`
    button                         | action                  | jobType
    ${findPlayButton}              | ${'play'}               | ${playableJob}
    ${findRetryButton}             | ${'retry'}              | ${retryableJob}
    ${findDownloadArtifactsButton} | ${'download artifacts'} | ${playableJob}
    ${findCancelButton}            | ${'cancel'}             | ${cancelableJob}
  `('displays the $action button', ({ button, jobType }) => {
    createComponent(jobType);

    expect(button().exists()).toBe(true);
  });

  it.each`
    button              | mutationResult             | action      | jobType          | mutationFile
    ${findPlayButton}   | ${MUTATION_SUCCESS_PLAY}   | ${'play'}   | ${playableJob}   | ${JobPlayMutation}
    ${findRetryButton}  | ${MUTATION_SUCCESS}        | ${'retry'}  | ${retryableJob}  | ${JobRetryMutation}
    ${findCancelButton} | ${MUTATION_SUCCESS_CANCEL} | ${'cancel'} | ${cancelableJob} | ${JobCancelMutation}
  `('performs the $action mutation', ({ button, mutationResult, jobType, mutationFile }) => {
    createComponent(jobType, mutationResult);

    button().vm.$emit('click');

    expect(mutate).toHaveBeenCalledWith({
      mutation: mutationFile,
      variables: {
        id: jobType.id,
      },
    });
  });

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
      createComponent(scheduledJob, MUTATION_SUCCESS_UNSCHEDULE);

      findUnscheduleButton().vm.$emit('click');

      expect(mutate).toHaveBeenCalledWith({
        mutation: JobUnscheduleMutation,
        variables: {
          id: scheduledJob.id,
        },
      });
    });

    it('shows the play job confirmation modal', async () => {
      createComponent(scheduledJob, MUTATION_SUCCESS);

      findPlayScheduledJobButton().vm.$emit('click');

      await nextTick();

      expect(findModal().exists()).toBe(true);
    });
  });
});
