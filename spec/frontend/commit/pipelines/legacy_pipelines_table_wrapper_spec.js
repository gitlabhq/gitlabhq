import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlModal, GlTableLite } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import LegacyPipelinesTableWrapper from '~/commit/pipelines/legacy_pipelines_table_wrapper.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { TOAST_MESSAGE } from '~/ci/pipeline_details/constants';
import axios from '~/lib/utils/axios_utils';
import getPipelineCreationRequests from '~/ci/merge_requests/graphql/queries/get_pipeline_creation_requests.query.graphql';
import pipelineCreationRequestsUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/pipeline_creation_requests_updated.subscription.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { generateMockPipeline } from 'jest/ci/merge_requests/mock_data';
import retryPipelineMutation from '~/ci/pipelines_page/graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from '~/ci/pipelines_page/graphql/mutations/cancel_pipeline.mutation.graphql';

Vue.use(VueApollo);

const $toast = {
  show: jest.fn(),
};

jest.mock('~/alert');

const generateMockPipelineCreationMergeRequest = (requests) => ({
  id: 'gid://gitlab/MergeRequest/3',
  iid: '3',
  title: 'Test MR',
  webPath: '/test/project/-/merge_requests/3',
  pipelineCreationRequests: requests,
});

const generatePipelineCreationRequestsResponse = ({
  requests = [
    { status: 'IN_PROGRESS', pipelineId: null, error: null, pipeline: null },
    {
      status: 'SUCCEEDED',
      pipelineId: '123',
      error: null,
      pipeline: generateMockPipeline({ id: '123' }),
    },
  ],
} = {}) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/5',
      fullPath: 'test/project',
      mergeRequest: generateMockPipelineCreationMergeRequest(requests),
    },
  },
});

const generatePipelineCreationSubscriptionUpdateResponse = ({
  requests = [
    { status: 'IN_PROGRESS', pipelineId: null, error: null, pipeline: null },
    {
      status: 'SUCCEEDED',
      pipelineId: '123',
      error: null,
      pipeline: generateMockPipeline({ id: '123' }),
    },
  ],
} = {}) => ({
  data: {
    ciPipelineCreationRequestsUpdated: generateMockPipelineCreationMergeRequest(requests),
  },
});

describe('Pipelines table in Commits and Merge requests', () => {
  let wrapper;
  let pipeline;
  let mock;
  let getPipelineCreationRequestsHandler;
  let mockSubscriptionHandler;
  const showMock = jest.fn();

  const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
  const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorEmptyState = () => wrapper.findByTestId('pipeline-error-empty-state');
  const findEmptyState = () => wrapper.findByTestId('pipeline-empty-state');
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findModal = () => wrapper.findComponent(GlModal);
  const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');
  const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');
  const findPipelinesTable = () => wrapper.findComponent(PipelinesTable);
  const findSkeletonLoader = () => wrapper.find('.gl-animate-skeleton-loader');
  const findCreationFailedAlert = () => wrapper.findComponent({ name: 'GlAlert' });

  const createComponent = ({
    props = {},
    handlers = [],
    mountFn = mountExtended,
    glFeatures = { ciPipelineCreationRequestsRealtime: false },
  } = {}) => {
    const requestHandlers = [
      [getPipelineCreationRequests, getPipelineCreationRequestsHandler],
      ...handlers,
    ];

    const subscriptionHandlers = [
      [pipelineCreationRequestsUpdatedSubscription, mockSubscriptionHandler],
    ];

    const apolloProvider = createMockApollo(requestHandlers);

    subscriptionHandlers.forEach(([query, handler]) => {
      apolloProvider.defaultClient.setRequestHandler(query, handler);
    });

    apolloProvider.defaultClient.clearStore();

    wrapper = mountFn(LegacyPipelinesTableWrapper, {
      propsData: {
        endpoint: 'endpoint.json',
        emptyStateSvgPath: 'foo',
        errorStateSvgPath: 'foo',
        ...props,
      },
      mocks: {
        $toast,
      },
      provide: {
        glFeatures,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: '<div />',
          methods: { show: showMock },
        }),
      },
      apolloProvider,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    getPipelineCreationRequestsHandler = jest
      .fn()
      .mockResolvedValue(generatePipelineCreationRequestsResponse());

    mockSubscriptionHandler = jest
      .fn()
      .mockResolvedValue(generatePipelineCreationSubscriptionUpdateResponse());

    const { pipelines } = fixture;

    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, []);

        createComponent();

        await waitForPromises();
      });

      it('should render the empty state', () => {
        expect(findTableRows()).toHaveLength(0);
        expect(findLoadingState().exists()).toBe(false);
        expect(findErrorEmptyState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should render correct empty state content', () => {
        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findMrPipelinesDocsLink().attributes('href')).toBe(
          '/help/ci/pipelines/merge_request_pipelines.md#prerequisites',
        );
        expect(findUserPermissionsDocsLink().attributes('href')).toBe(
          '/help/user/permissions.md#cicd',
        );
        expect(findEmptyState().text()).toContain(
          'To run a merge request pipeline, the jobs in the CI/CD configuration file must be configured to run in merge request pipelines ' +
            'and you must have sufficient permissions in the source project.',
        );
      });
    });

    describe('with pagination', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline], {
          'X-TOTAL': 10,
          'X-PER-PAGE': 2,
          'X-PAGE': 1,
          'X-TOTAL-PAGES': 5,
          'X-NEXT-PAGE': 2,
          'X-PREV-PAGE': 2,
        });

        createComponent();

        await waitForPromises();
      });

      it('should make an API request when using pagination', async () => {
        expect(mock.history.get).toHaveLength(1);

        wrapper.find('[data-testid="gl-pagination-next"]').trigger('click');

        await waitForPromises();

        expect(mock.history.get).toHaveLength(2);
        expect(mock.history.get[1].params.page).toBe('2');
      });
    });

    describe('with pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline], { 'x-total': 10 });

        createComponent();

        await waitForPromises();
      });

      it('should render a table with the received pipelines', () => {
        expect(findTable().exists()).toBe(true);
        expect(findTableRows()).toHaveLength(1);
        expect(findLoadingState().exists()).toBe(false);
        expect(findErrorEmptyState().exists()).toBe(false);
      });

      describe('pipeline badge counts', () => {
        it('should receive update-pipelines-count event', () => {
          const element = document.createElement('div');
          document.body.appendChild(element);

          return new Promise((resolve) => {
            element.addEventListener('update-pipelines-count', (event) => {
              expect(event.detail.pipelineCount).toEqual(10);
              resolve();
            });

            createComponent();

            element.appendChild(wrapper.vm.$el);
          });
        });
      });
    });
  });

  describe('run pipeline button', () => {
    let pipelineCopy;

    beforeEach(() => {
      pipelineCopy = { ...pipeline };
    });

    describe('when latest pipeline has detached flag', () => {
      it('renders the run pipeline button', async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;
        pipelineCopy.flags.merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent();

        await waitForPromises();

        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findRunPipelineBtnMobile().exists()).toBe(true);
      });
    });

    describe('when latest pipeline does not have detached flag', () => {
      it('does not render the run pipeline button', async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = false;
        pipelineCopy.flags.merge_request_pipeline = false;

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent();

        await waitForPromises();

        expect(findRunPipelineBtn().exists()).toBe(false);
        expect(findRunPipelineBtnMobile().exists()).toBe(false);
      });
    });

    describe('on click', () => {
      beforeEach(async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent({
          props: {
            canRunPipeline: true,
            projectId: '5',
            mergeRequestId: 3,
          },
        });

        await waitForPromises();
      });

      describe('success', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();
        });

        describe('when the table is a merge request table', () => {
          beforeEach(async () => {
            createComponent({
              props: {
                canRunPipeline: true,
                isMergeRequestTable: true,
                mergeRequestId: 3,
                projectId: '5',
                targetProjectFullPath: 'test/project',
              },
            });

            await waitForPromises();
          });

          it('on desktop, shows a loading button', async () => {
            await findRunPipelineBtn().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);
          });

          it('on mobile, shows a loading button', async () => {
            await findRunPipelineBtnMobile().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);
          });
        });

        describe('when the table is not a merge request table', () => {
          it('displays a toast message during pipeline creation', async () => {
            await findRunPipelineBtn().trigger('click');

            expect($toast.show).toHaveBeenCalledWith(TOAST_MESSAGE);
          });

          it('on desktop, shows a loading button', async () => {
            await findRunPipelineBtn().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);

            await waitForPromises();

            expect(findRunPipelineBtn().props('loading')).toBe(false);
          });

          it('on mobile, shows a loading button', async () => {
            await findRunPipelineBtnMobile().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);

            await waitForPromises();

            expect(findRunPipelineBtn().props('disabled')).toBe(false);
            expect(findRunPipelineBtn().props('loading')).toBe(false);
          });
        });
      });

      describe('failure', () => {
        const permissionsMsg = 'You do not have permission to run a pipeline on this branch.';
        const defaultMsg =
          'An error occurred while trying to run a new pipeline for this merge request.';

        it.each`
          status                               | message
          ${HTTP_STATUS_BAD_REQUEST}           | ${defaultMsg}
          ${HTTP_STATUS_UNAUTHORIZED}          | ${permissionsMsg}
          ${HTTP_STATUS_INTERNAL_SERVER_ERROR} | ${defaultMsg}
        `('displays permissions error message', async ({ status, message }) => {
          const response = { response: { status } };

          jest.spyOn(Api, 'postMergeRequestPipeline').mockRejectedValue(response);

          await findRunPipelineBtn().trigger('click');

          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message,
            primaryButton: {
              text: 'Learn more',
              link: '/help/ci/pipelines/merge_request_pipelines.md',
            },
          });
        });
      });
    });

    describe('on click for fork merge request', () => {
      beforeEach(async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent({
          props: {
            projectId: '5',
            mergeRequestId: 3,
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });

        jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();

        await waitForPromises();
      });

      it('on desktop, shows a security warning modal', async () => {
        await findRunPipelineBtn().trigger('click');

        await nextTick();

        expect(findModal()).not.toBeNull();
      });

      it('on mobile, shows a security warning modal', async () => {
        await findRunPipelineBtnMobile().trigger('click');

        expect(findModal()).not.toBeNull();
      });
    });

    describe('when no pipelines were created on a forked merge request', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, []);

        createComponent({
          props: {
            projectId: '5',
            mergeRequestId: 3,
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });

        await waitForPromises();
      });

      it('should show security modal from empty state run pipeline button', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findModal().exists()).toBe(true);

        findRunPipelineBtn().trigger('click');

        expect(showMock).toHaveBeenCalled();
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(async () => {
      mock.onGet('endpoint.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

      createComponent();

      await waitForPromises();
    });

    it('should render error state', () => {
      expect(findErrorEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline]);

      createComponent({ mountFn: shallowMountExtended });

      await waitForPromises();
    });

    describe('When cancelling a pipeline', () => {
      it('sends the cancel action', async () => {
        const cancelPipelineMutationHandler = jest.fn().mockResolvedValue({
          data: {
            pipelineCancel: {
              errors: [],
            },
          },
        });

        const cancelablePipeline = {
          ...pipeline,
          cancel_path: '/root/project/-/pipelines/1/cancel',
          flags: {
            ...pipeline.flags,
            cancelable: true,
          },
        };

        createComponent({
          mountFn: shallowMountExtended,
          handlers: [[cancelPipelineMutation, cancelPipelineMutationHandler]],
        });

        await waitForPromises();

        findPipelinesTable().vm.$emit('cancel-pipeline', cancelablePipeline);

        await waitForPromises();

        expect(cancelPipelineMutationHandler).toHaveBeenCalledWith({
          id: `gid://gitlab/Ci::Pipeline/${cancelablePipeline.id}`,
        });
      });
    });

    describe('When retrying a pipeline', () => {
      it('sends the retry action', async () => {
        const retryPipelineMutationHandler = jest.fn().mockResolvedValue({
          data: {
            pipelineRetry: {
              errors: [],
            },
          },
        });

        createComponent({
          mountFn: shallowMountExtended,
          handlers: [[retryPipelineMutation, retryPipelineMutationHandler]],
        });

        await waitForPromises();

        findPipelinesTable().vm.$emit('retry-pipeline', pipeline);

        await waitForPromises();

        expect(retryPipelineMutationHandler).toHaveBeenCalledWith({
          id: `gid://gitlab/Ci::Pipeline/${pipeline.id}`,
        });
      });
    });

    describe('When refreshing a pipeline', () => {
      it('calls the pipelines endpoint again', async () => {
        expect(mock.history.get).toHaveLength(1);

        findPipelinesTable().vm.$emit('refresh-pipelines-table');

        await waitForPromises();

        expect(mock.history.get).toHaveLength(2);
        expect(mock.history.get[1].url).toContain('endpoint.json');
      });
    });
  });

  describe('GraphQL pipeline creation requests', () => {
    beforeAll(() => {
      jest.useFakeTimers();
    });

    afterAll(() => {
      jest.useRealTimers();
    });

    beforeEach(() => {
      mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [
        {
          ...pipeline,
          flags: {
            ...pipeline.flags,
            detached_merge_request_pipeline: true,
            merge_request_pipeline: true,
          },
        },
      ]);
    });

    afterEach(() => {
      jest.clearAllTimers();
    });

    describe('with feature flag ci_pipeline_creation_requests_realtime', () => {
      describe('when feature flag is OFF', () => {
        it('skips getPipelineCreationRequests query', async () => {
          createComponent({
            props: {
              isMergeRequestTable: true,
              targetProjectFullPath: 'test/project',
              mergeRequestId: 3,
            },
          });

          await waitForPromises();

          expect(getPipelineCreationRequestsHandler).not.toHaveBeenCalled();
        });

        it('skips subscription', async () => {
          createComponent({
            props: {
              isMergeRequestTable: true,
              targetProjectFullPath: 'test/project',
              mergeRequestId: 3,
            },
          });

          await waitForPromises();

          expect(mockSubscriptionHandler).not.toHaveBeenCalled();
        });
      });

      describe('when feature flag is ON', () => {
        let glFeatures;

        beforeEach(() => {
          glFeatures = { ciPipelineCreationRequestsRealtime: true };
        });

        describe('getPipelineCreationRequests query', () => {
          it('calls getPipelineCreationRequests query with correct variables', async () => {
            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            expect(getPipelineCreationRequestsHandler).toHaveBeenCalledWith({
              fullPath: 'test/project',
              mergeRequestIid: '3',
            });
          });

          it.each`
            scenario                              | isMergeRequestTable | targetProjectFullPath | mergeRequestId
            ${'not on merge request table'}       | ${false}            | ${'test/project'}     | ${3}
            ${'mergeRequestId is missing'}        | ${true}             | ${'test/project'}     | ${null}
            ${'targetProjectFullPath is missing'} | ${true}             | ${null}               | ${3}
          `(
            'skips query when $scenario',
            async ({ isMergeRequestTable, targetProjectFullPath, mergeRequestId }) => {
              createComponent({
                props: {
                  isMergeRequestTable,
                  targetProjectFullPath,
                  mergeRequestId,
                },
                glFeatures,
              });

              await waitForPromises();

              expect(getPipelineCreationRequestsHandler).not.toHaveBeenCalled();
            },
          );
        });

        describe('pipelineCreationRequestsUpdated subscription', () => {
          it('calls subscription with correct variables', async () => {
            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            expect(mockSubscriptionHandler).toHaveBeenCalledWith({
              mergeRequestId: 'gid://gitlab/MergeRequest/3',
            });
          });

          const mockMergeRequestGlobalId = () =>
            getPipelineCreationRequestsHandler.mockResolvedValue({
              data: {
                project: {
                  id: 'gid://gitlab/Project/5',
                  mergeRequest: { id: null, pipelineCreationRequests: [] },
                },
              },
            });

          it.each`
            scenario                                   | isMergeRequestTable | targetProjectFullPath | mergeRequestId | mockHandlerSetup
            ${'not on merge request table'}            | ${false}            | ${'test/project'}     | ${3}           | ${undefined}
            ${'mergeRequestId is missing'}             | ${true}             | ${'test/project'}     | ${null}        | ${undefined}
            ${'targetProjectFullPath is missing'}      | ${true}             | ${null}               | ${3}           | ${undefined}
            ${'mergeRequestGlobalId is not available'} | ${true}             | ${'test/project'}     | ${3}           | ${mockMergeRequestGlobalId}
          `(
            'skips subscription when $scenario',
            async ({
              isMergeRequestTable,
              targetProjectFullPath,
              mergeRequestId,
              mockHandlerSetup,
            }) => {
              if (mockHandlerSetup) {
                mockHandlerSetup();
              }

              createComponent({
                props: {
                  isMergeRequestTable,
                  targetProjectFullPath,
                  mergeRequestId,
                },
                glFeatures,
              });

              await waitForPromises();

              expect(mockSubscriptionHandler).not.toHaveBeenCalled();
            },
          );
        });

        describe('Pipeline creation failed alert', () => {
          it('shows alert when pipeline creation fails', async () => {
            const failedRequests = [
              { status: 'FAILED', pipelineId: null, pipeline: null, error: 'Creation failed' },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: failedRequests }),
            );

            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            expect(findCreationFailedAlert().exists()).toBe(true);
            expect(findCreationFailedAlert().text()).toBe(
              'Pipeline creation failed. Please try again.',
            );
            expect(findCreationFailedAlert().props('variant')).toBe('danger');
            expect(findCreationFailedAlert().props('dismissible')).toBe(true);
          });

          it('hides alert when dismissed', async () => {
            const failedRequests = [
              { status: 'FAILED', pipelineId: null, pipeline: null, error: 'Creation failed' },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: failedRequests }),
            );

            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            expect(findCreationFailedAlert().exists()).toBe(true);

            await findCreationFailedAlert().vm.$emit('dismiss');

            expect(findCreationFailedAlert().exists()).toBe(false);
          });

          it('shows alert when failure count increases via subscription', async () => {
            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            expect(findCreationFailedAlert().exists()).toBe(false);

            const failedRequests = [
              { status: 'FAILED', pipelineId: null, pipeline: null, error: 'Creation failed' },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: failedRequests }),
            );

            await wrapper.vm.$apollo.queries.pipelineCreationRequests.refetch();
            await waitForPromises();

            await nextTick();

            expect(findCreationFailedAlert().exists()).toBe(true);
          });
        });

        describe('Run pipeline button', () => {
          describe('when there are in progress pipeline creation requests', () => {
            it.each([
              {
                buttonType: 'desktop',
                findRunButton: () => findRunPipelineBtn(),
              },
              {
                buttonType: 'mobile',
                findRunButton: () => findRunPipelineBtnMobile(),
              },
              {
                buttonType: 'empty state',
                findRunButton: () => findRunPipelineBtn(),
              },
            ])('disables the $buttonType button & enables loading', async ({ findRunButton }) => {
              const inProgressRequests = [
                { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
              ];

              getPipelineCreationRequestsHandler.mockResolvedValue(
                generatePipelineCreationRequestsResponse({ requests: inProgressRequests }),
              );

              createComponent({
                props: {
                  canRunPipeline: true,
                  isMergeRequestTable: true,
                  mergeRequestId: 3,
                  projectId: '5',
                  targetProjectFullPath: 'test/project',
                },
                glFeatures,
              });

              await waitForPromises();

              expect(findRunButton().exists()).toBe(true);
              expect(findRunButton().props('disabled')).toBe(true);
              expect(findRunButton().props('loading')).toBe(true);
            });
          });

          describe('shows skeleton loader', () => {
            it('after a small delay when run pipeline button is clicked', async () => {
              createComponent({
                props: {
                  canRunPipeline: true,
                  isMergeRequestTable: true,
                  mergeRequestId: 3,
                  projectId: '5',
                  targetProjectFullPath: 'test/project',
                },
                glFeatures,
              });

              await waitForPromises();

              expect(findSkeletonLoader().exists()).toBe(false);

              await findRunPipelineBtn().trigger('click');

              expect(findSkeletonLoader().exists()).toBe(false);

              jest.runAllTimers();
              await nextTick();

              expect(findSkeletonLoader().exists()).toBe(true);
            });

            it('when hasInProgressCreationRequests becomes true', async () => {
              getPipelineCreationRequestsHandler.mockResolvedValue(
                generatePipelineCreationRequestsResponse({
                  requests: [
                    { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
                  ],
                }),
              );

              createComponent({
                props: {
                  canRunPipeline: true,
                  isMergeRequestTable: true,
                  mergeRequestId: 3,
                  projectId: '5',
                  targetProjectFullPath: 'test/project',
                },
                glFeatures,
              });

              await waitForPromises();

              expect(findSkeletonLoader().exists()).toBe(false);

              jest.runAllTimers();
              await nextTick();

              expect(findSkeletonLoader().exists()).toBe(true);
            });
          });
        });

        describe('debounced pipeline loader', () => {
          it('shows skeleton loader after debounce delay when run pipeline button is clicked', async () => {
            createComponent({
              props: {
                canRunPipeline: true,
                isMergeRequestTable: true,
                mergeRequestId: 3,
                projectId: '5',
                targetProjectFullPath: 'test/project',
              },
              glFeatures,
            });

            await waitForPromises();

            expect(findSkeletonLoader().exists()).toBe(false);

            findRunPipelineBtn().trigger('click');

            expect(findSkeletonLoader().exists()).toBe(false);

            jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
            await nextTick();

            expect(findSkeletonLoader().exists()).toBe(true);
          });

          it('stops showing skeleton loader when pipeline creation completes', async () => {
            const inProgressRequests = [
              { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
            ];
            const completedRequests = [
              {
                status: 'SUCCEEDED',
                pipelineId: '123',
                pipeline: generateMockPipeline({ id: '123' }),
                error: null,
              },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: inProgressRequests }),
            );

            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
            await nextTick();

            expect(findSkeletonLoader().exists()).toBe(true);

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: completedRequests }),
            );

            mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, []);

            findPipelinesTable().vm.$emit('refresh-pipelines-table');
            await waitForPromises();

            expect(findSkeletonLoader().exists()).toBe(false);
          });

          it('continues showing skeleton loader when there are still in-progress requests', async () => {
            const inProgressRequests = [
              { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
              { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: inProgressRequests }),
            );

            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
            await nextTick();

            expect(findSkeletonLoader().exists()).toBe(true);

            const mixedRequests = [
              { status: 'IN_PROGRESS', pipelineId: null, pipeline: null, error: null },
              {
                status: 'SUCCEEDED',
                pipelineId: '123',
                pipeline: generateMockPipeline({ id: '123' }),
                error: null,
              },
            ];

            getPipelineCreationRequestsHandler.mockResolvedValue(
              generatePipelineCreationRequestsResponse({ requests: mixedRequests }),
            );

            mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [
              {
                ...pipeline,
                flags: {
                  ...pipeline.flags,
                  detached_merge_request_pipeline: true,
                  merge_request_pipeline: true,
                },
              },
            ]);
            findPipelinesTable().vm.$emit('refresh-pipelines-table');
            await waitForPromises();

            expect(findSkeletonLoader().exists()).toBe(true);
          });

          it('clears timeout on component unmount', async () => {
            createComponent({
              props: {
                isMergeRequestTable: true,
                targetProjectFullPath: 'test/project',
                mergeRequestId: 3,
              },
              glFeatures,
            });

            await waitForPromises();

            const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');

            findRunPipelineBtn().trigger('click');

            wrapper.destroy();

            expect(clearTimeoutSpy).toHaveBeenCalled();
          });
        });
      });
    });
  });
});
