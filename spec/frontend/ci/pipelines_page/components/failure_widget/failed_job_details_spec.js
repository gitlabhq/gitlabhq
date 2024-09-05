import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import FailedJobDetails from '~/ci/pipelines_page/components/failure_widget/failed_job_details.vue';
import RetryMrFailedJobMutation from '~/ci/merge_requests/graphql/mutations/retry_mr_failed_job.mutation.graphql';
import { BRIDGE_KIND } from '~/ci/pipeline_details/graph/constants';
import { job } from './mock';

Vue.use(VueApollo);
jest.mock('~/alert');

const createFakeEvent = () => ({ stopPropagation: jest.fn() });

describe('FailedJobDetails component', () => {
  let wrapper;
  let mockRetryResponse;

  const retrySuccessResponse = {
    data: {
      jobRetry: {
        errors: [],
      },
    },
  };

  const defaultProps = {
    job,
  };

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [[RetryMrFailedJobMutation, mockRetryResponse]];

    wrapper = shallowMountExtended(FailedJobDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: createMockApollo(handlers),
    });
  };

  const findJobId = () => wrapper.findByTestId('job-id-link');
  const findJobName = () => wrapper.findByTestId('job-name-link');
  const findRetryButton = () => wrapper.findByTestId('retry-button');
  const findStageName = () => wrapper.findByTestId('job-stage-name');

  beforeEach(() => {
    mockRetryResponse = jest.fn();
    mockRetryResponse.mockResolvedValue(retrySuccessResponse);
  });

  describe('ui', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the job name', () => {
      expect(findJobName().exists()).toBe(true);
    });

    it('renders the stage name', () => {
      expect(findStageName().exists()).toBe(true);
    });

    it('renders the job id as a link', () => {
      const jobId = getIdFromGraphQLId(defaultProps.job.id);

      expect(findJobId().exists()).toBe(true);
      expect(findJobId().text()).toContain(String(jobId));
    });
  });

  describe('Retry action', () => {
    describe('when the job is not retryable', () => {
      beforeEach(() => {
        createComponent({ props: { job: { ...job, retryable: false } } });
      });

      it('disables the retry button', () => {
        expect(findRetryButton().props().disabled).toBe(true);
      });
    });

    describe('when the job is a bridge', () => {
      beforeEach(() => {
        createComponent({ props: { job: { ...job, kind: BRIDGE_KIND } } });
      });

      it('disables the retry button', () => {
        expect(findRetryButton().props().disabled).toBe(true);
      });
    });

    describe('when the job is retryable', () => {
      describe('and user has permission to update the build', () => {
        beforeEach(() => {
          createComponent();
        });

        it('enables the retry button', () => {
          expect(findRetryButton().props().disabled).toBe(false);
        });

        describe('when clicking on the retry button', () => {
          it('passes the loading state to the button', async () => {
            await findRetryButton().vm.$emit('click', createFakeEvent());

            expect(findRetryButton().props().loading).toBe(true);
          });

          describe('and it succeeds', () => {
            beforeEach(async () => {
              findRetryButton().vm.$emit('click', createFakeEvent());
              await waitForPromises();
            });

            it('is no longer loading', () => {
              expect(findRetryButton().props().loading).toBe(false);
            });

            it('calls the retry mutation', () => {
              expect(mockRetryResponse).toHaveBeenCalled();
              expect(mockRetryResponse).toHaveBeenCalledWith({
                id: job.id,
              });
            });

            it('emits the `retried-job` event', () => {
              expect(wrapper.emitted('job-retried')).toStrictEqual([[job.name]]);
            });
          });

          describe('and it fails', () => {
            const customErrorMsg = 'Custom error message from API';

            beforeEach(async () => {
              mockRetryResponse.mockResolvedValue({
                data: { jobRetry: { errors: [customErrorMsg] } },
              });
              findRetryButton().vm.$emit('click', createFakeEvent());

              await waitForPromises();
            });

            it('shows an error message', () => {
              expect(createAlert).toHaveBeenCalledWith({ message: customErrorMsg });
            });

            it('does not emits the `refetch-jobs` event', () => {
              expect(wrapper.emitted('refetch-jobs')).toBeUndefined();
            });
          });
        });
      });

      describe('and user does not have permission to update the build', () => {
        beforeEach(() => {
          createComponent({
            props: { job: { ...job, retryable: true, userPermissions: { updateBuild: false } } },
          });
        });

        it('disables the retry button', () => {
          expect(findRetryButton().props().disabled).toBe(true);
        });
      });
    });
  });
});
