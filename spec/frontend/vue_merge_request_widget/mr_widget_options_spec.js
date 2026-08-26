import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription as createMockApolloSubscription } from 'mock-apollo-client';
import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import getStateQueryResponse from 'test_fixtures/graphql/merge_requests/get_state.query.graphql.json';
import readyToMergeResponse from 'test_fixtures/graphql/merge_requests/states/ready_to_merge.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { setFaviconOverlay } from '~/lib/utils/favicon';
import notify from '~/lib/utils/notify';
import SmartInterval from '~/smart_interval';
import { STATUS_CLOSED, STATUS_OPEN, STATUS_MERGED } from '~/issues/constants';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import Preparing from '~/vue_merge_request_widget/components/states/mr_widget_preparing.vue';
import ShaMismatch from '~/vue_merge_request_widget/components/states/sha_mismatch.vue';
import MergedState from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import WidgetContainer from '~/vue_merge_request_widget/components/widget/app.vue';
import MrWidgetAlertMessage from '~/vue_merge_request_widget/components/mr_widget_alert_message.vue';
import getStateQuery from 'ee_else_ce/vue_merge_request_widget/queries/get_state.query.graphql';
import getStateSubscription from '~/vue_merge_request_widget/queries/get_state.subscription.graphql';
import readyToMergeSubscription from '~/vue_merge_request_widget/queries/states/ready_to_merge.subscription.graphql';
import mrPipelineUpdatedSubscription from '~/vue_merge_request_widget/subscriptions/mr_pipeline_updated.subscription.graphql';
import mrPipelineCreationRequestUpdated from '~/vue_merge_request_widget/subscriptions/mr_pipeline_creation_request_updated.subscription.graphql';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_merge_request_widget/widgets/security_reports/graphql/security_report_merge_request_download_paths.query.graphql';
import readyToMergeQuery from '~/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import approvalsQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import approvedBySubscription from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.subscription.graphql';
import userPermissionsQuery from '~/vue_merge_request_widget/queries/permissions.query.graphql';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';
import mergeChecksQuery from '~/vue_merge_request_widget/queries/merge_checks.query.graphql';
import mergeChecksSubscription from '~/vue_merge_request_widget/queries/merge_checks.subscription.graphql';
import userPermissionsReviewerQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import missingBranchQuery from '~/vue_merge_request_widget/queries/states/missing_branch.query.graphql';

import { faviconDataUrl, overlayDataUrl } from '../lib/utils/mock_data';
import mockData, { mockDeployment, mockMergePipeline, mockPostMergeDeployments } from './mock_data';

jest.mock('~/api.js');

jest.mock('~/smart_interval');

jest.mock('~/lib/utils/favicon');

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  ...jest.requireActual('~/sentry/sentry_browser_wrapper'),
  captureException: jest.fn(),
}));

Vue.use(VueApollo);

describe('MrWidgetOptions', () => {
  let stateQueryHandler;
  let queryResponse;
  let wrapper;
  let mock;

  const COLLABORATION_MESSAGE = 'Members who can merge are allowed to add commits';

  const createComponent = ({
    updatedMrData = {},
    options = {},
    data = {},
    stateSubscriptionHandler = jest
      .fn()
      .mockResolvedValue({ data: { mergeRequestMergeStatusUpdated: {} } }),
    mountFn = shallowMountExtended,
  } = {}) => {
    gl.mrWidgetData = { ...mockData, ...updatedMrData };
    const mrData = { ...mockData, ...updatedMrData };
    const mockedApprovalsSubscription = createMockApolloSubscription();
    queryResponse = {
      data: {
        project: {
          ...getStateQueryResponse.data.project,
          mergeTrains: null,
          mergeRequest: {
            ...getStateQueryResponse.data.project.mergeRequest,
            mergeError: mrData.mergeError || null,
            mergeTrainCar: null,
            commitCount:
              mrData.commitCount ?? getStateQueryResponse.data.project.mergeRequest.commitCount,
            detailedMergeStatus:
              mrData.detailedMergeStatus ||
              getStateQueryResponse.data.project.mergeRequest.detailedMergeStatus,
          },
        },
      },
    };
    stateQueryHandler = stateQueryHandler || jest.fn().mockResolvedValue(queryResponse);

    const queryHandlers = [
      [approvalsQuery, jest.fn().mockResolvedValue(approvedByCurrentUser)],
      [getStateQuery, stateQueryHandler],
      [readyToMergeQuery, jest.fn().mockResolvedValue(readyToMergeResponse)],
      [
        userPermissionsQuery,
        jest.fn().mockResolvedValue({
          data: { project: { mergeRequest: { userPermissions: {} } } },
        }),
      ],
      [
        userPermissionsReviewerQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                userPermissions: { adminMergeRequest: false, canMerge: true },
              },
            },
          },
        }),
      ],
      [
        conflictsStateQuery,
        jest.fn().mockResolvedValue({ data: { project: { mergeRequest: {} } } }),
      ],
      [securityReportMergeRequestDownloadPathsQuery, jest.fn().mockResolvedValue(null)],
      [
        mergeChecksQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: 1,
              mergeRequest: { id: 1, userPermissions: { canMerge: true }, mergeabilityChecks: [] },
            },
          },
        }),
      ],
      [
        missingBranchQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                sourceBranchExists: false,
              },
            },
          },
        }),
      ],
      ...(options.apolloMock || []),
    ];
    const subscriptionHandlers = [
      [approvedBySubscription, () => mockedApprovalsSubscription],
      [getStateSubscription, stateSubscriptionHandler],
      [readyToMergeSubscription, () => createMockApolloSubscription()],
      [mergeChecksSubscription, () => createMockApolloSubscription()],
      [mrPipelineUpdatedSubscription, () => createMockApolloSubscription()],
      [mrPipelineCreationRequestUpdated, () => createMockApolloSubscription()],
    ];
    const apolloProvider = createMockApollo(queryHandlers);

    subscriptionHandlers.forEach(([query, stream]) => {
      apolloProvider.defaultClient.setRequestHandler(query, stream);
    });

    wrapper = mountFn(MrWidgetOptions, {
      propsData: { mrData },
      data() {
        return {
          loading: false,
          ...data,
        };
      },

      ...options,
      apolloProvider,
    });

    return axios.waitForAll();
  };

  const findApprovalsWidget = () => wrapper.findComponent(Approvals);
  const findPreparingWidget = () => wrapper.findComponent(Preparing);
  const findMergedPipelineContainer = () => wrapper.findByTestId('merged-pipeline-container');
  const findPipelineContainer = () => wrapper.findComponentByTestId('pipeline-container');
  const findAlertMessage = () => wrapper.findComponent(MrWidgetAlertMessage);
  const findMergePipelineForkAlert = () => wrapper.findByTestId('merge-pipeline-fork-warning');
  const findWidgetContainer = () => wrapper.findComponent(WidgetContainer);
  const findMergeError = () => wrapper.findByTestId('merge-error');

  beforeEach(() => {
    gon.features = {};
    mock = new MockAdapter(axios);
    mock.onGet(mockData.merge_request_widget_path).reply(HTTP_STATUS_OK, {});
    mock.onGet(mockData.merge_request_cached_widget_path).reply(HTTP_STATUS_OK, {});
  });

  afterEach(() => {
    stateQueryHandler = null;
    gl.mrWidgetData = {};
  });

  describe('default', () => {
    describe('computed', () => {
      describe('componentName', () => {
        it.each`
          state            | componentName    | component
          ${STATUS_MERGED} | ${'MergedState'} | ${MergedState}
          ${'shaMismatch'} | ${'ShaMismatch'} | ${ShaMismatch}
        `('should translate $state into $componentName component', async ({ state, component }) => {
          await createComponent();

          wrapper.vm.mr = {
            ...wrapper.vm.mr,
            setGraphqlData: jest.fn(),
            state,
          };

          await nextTick();
          expect(wrapper.findComponent(component).exists()).toBe(true);
        });
      });

      describe('MrWidgetPipelineContainer', () => {
        it('renders the pipeline container when it has CI', () => {
          createComponent({ updatedMrData: { has_ci: true } });
          expect(findPipelineContainer().exists()).toBe(true);
        });

        it('does not render the pipeline container when it does not have CI', () => {
          createComponent({ updatedMrData: { has_ci: false } });
          expect(findPipelineContainer().exists()).toBe(false);
        });
      });

      describe('shouldRenderCollaborationStatus', () => {
        it('renders collaboration message when collaboration is allowed and the MR is open', () => {
          createComponent({
            updatedMrData: { allow_collaboration: true, state: STATUS_OPEN, not: false },
          });
          expect(findPipelineContainer().props('mr')).toMatchObject({
            allowCollaboration: true,
            isOpen: true,
          });
          expect(wrapper.text()).toContain(COLLABORATION_MESSAGE);
        });

        it('does not render collaboration message when collaboration is allowed and the MR is closed', () => {
          createComponent({
            updatedMrData: { allow_collaboration: true, state: STATUS_CLOSED, not: true },
          });
          expect(findPipelineContainer().props('mr')).toMatchObject({
            allowCollaboration: true,
            isOpen: false,
          });
          expect(wrapper.text()).not.toContain(COLLABORATION_MESSAGE);
        });

        it('does not render collaboration message when collaboration is not allowed and the MR is closed', () => {
          createComponent({
            updatedMrData: { allow_collaboration: undefined, state: STATUS_CLOSED, not: true },
          });
          expect(findPipelineContainer().props('mr')).toMatchObject({
            allowCollaboration: undefined,
            isOpen: false,
          });
          expect(wrapper.text()).not.toContain(COLLABORATION_MESSAGE);
        });

        it('does not render collaboration message when collaboration is not allowed and the MR is open', () => {
          createComponent({
            updatedMrData: { allow_collaboration: undefined, state: STATUS_OPEN, not: true },
          });
          expect(findPipelineContainer().props('mr')).toMatchObject({
            allowCollaboration: undefined,
            isOpen: true,
          });
          expect(wrapper.text()).not.toContain(COLLABORATION_MESSAGE);
        });
      });

      describe('showMergePipelineForkWarning', () => {
        it('hides the alert when the source project and target project are the same', async () => {
          createComponent({
            updatedMrData: {
              source_project_id: 1,
              target_project_id: 1,
            },
          });
          await nextTick();
          wrapper.vm.mt = {
            ...wrapper.vm.mr,
            setGraphqlData: jest.fn(),
            mergePipelinesEnabled: true,
          };

          await nextTick();
          expect(findMergePipelineForkAlert().exists()).toBe(false);
        });

        it('hides the alert when merged results pipelines are not enabled', async () => {
          createComponent({
            updatedMrData: {
              source_project_id: 1,
              target_project_id: 2,
            },
          });
          await nextTick();
          expect(findMergePipelineForkAlert().exists()).toBe(false);
        });

        it('shows the alert when merged results pipelines are enabled and the source project and target project are different', async () => {
          createComponent({
            updatedMrData: {
              source_project_id: 1,
              target_project_id: 2,
            },
          });
          await nextTick();

          wrapper.vm.mr = {
            ...wrapper.vm.mr,
            setGraphqlData: jest.fn(),
            setGraphqlSubscriptionData: jest.fn(),
            mergePipelinesEnabled: true,
          };

          await nextTick();
          expect(findMergePipelineForkAlert().exists()).toBe(true);
        });
      });
    });

    describe('methods', () => {
      describe('checkStatus', () => {
        const updatedMrData = { foo: 1, title: '<test>' };
        beforeEach(() => {
          mock
            .onGet(mockData.merge_request_widget_path)
            .reply(HTTP_STATUS_OK, { ...mockData, ...updatedMrData });
          mock
            .onGet(mockData.merge_request_cached_widget_path)
            .reply(HTTP_STATUS_OK, { ...mockData, ...updatedMrData });
        });

        it('checks the status of the pipelines', async () => {
          const callback = jest.fn();
          await createComponent({ updatedMrData });
          await waitForPromises();
          eventHub.$emit('mr-widget-update-requested', callback);
          await waitForPromises();
          expect(callback).toHaveBeenCalled();
        });

        it('notifies the user of the pipeline status', async () => {
          jest.spyOn(notify, 'notifyMe').mockImplementation(() => {});
          const logoFilename = 'logo.png';
          await createComponent({
            updatedMrData: { gitlabLogo: logoFilename, ci_status: 'failed', title: '<test>' },
          });
          eventHub.$emit('mr-widget-update-requested');
          await waitForPromises();
          expect(notify.notifyMe).toHaveBeenCalledWith(
            `Pipeline passed`,
            `Pipeline passed for "<test>"`,
            logoFilename,
          );
        });

        it('updates the stores data', async () => {
          const mockSetData = jest.fn();
          await createComponent({
            data: {
              mr: {
                setData: mockSetData,
                setGraphqlData: jest.fn(),
                setGraphqlSubscriptionData: jest.fn(),
              },
            },
          });
          eventHub.$emit('mr-widget-update-requested');
          expect(mockSetData).toHaveBeenCalled();
        });
      });

      describe('initDeploymentsPolling', () => {
        beforeEach(async () => {
          await createComponent();
        });

        it('should call SmartInterval', () => {
          wrapper.vm.initDeploymentsPolling();

          expect(SmartInterval).toHaveBeenCalledWith(
            expect.objectContaining({
              callback: wrapper.vm.fetchPreMergeDeployments,
            }),
          );
        });
      });

      describe('fetchDeployments', () => {
        beforeEach(async () => {
          mock
            .onGet(mockData.ci_environments_status_path)
            .reply(() => [HTTP_STATUS_OK, [{ id: 1, status: SUCCESS }]]);
          await createComponent();
        });

        it('should fetch deployments', async () => {
          expect(findPipelineContainer().props('mr').deployments).toHaveLength(0);
          expect(findMergedPipelineContainer().exists()).toBe(false);
          eventHub.$emit('fetch-deployments', {});
          await waitForPromises();
          expect(findPipelineContainer().props('isPostMerge')).toBe(false);
          expect(findMergedPipelineContainer().exists()).toBe(false);
          expect(findPipelineContainer().props('mr').deployments).toHaveLength(1);
          expect(findPipelineContainer().props('mr').deployments[0].id).toBe(1);
        });
      });

      describe('fetchActionsContent', () => {
        const innerHTML = 'hello world';
        beforeEach(async () => {
          jest.spyOn(document, 'dispatchEvent');
          mock.onGet(mockData.commit_change_content_path).reply(() => [HTTP_STATUS_OK, innerHTML]);
          await createComponent();
        });

        it('should fetch content of Cherry Pick and Revert modals', async () => {
          eventHub.$emit('fetch-actions-content');
          await waitForPromises();
          expect(document.body.textContent).toContain(innerHTML);
          expect(document.dispatchEvent).toHaveBeenCalledWith(
            new CustomEvent('merged:UpdateActions'),
          );
        });
      });

      describe('bindEventHubListeners', () => {
        let mockSetData;

        beforeEach(async () => {
          mockSetData = jest.spyOn(MRWidgetStore.prototype, 'setData');
          await createComponent();
        });

        it('refetches when the `mr-widget-update-requested` event is emitted', async () => {
          expect(stateQueryHandler).toHaveBeenCalledTimes(1);
          eventHub.$emit('mr-widget-update-requested', () => {});
          await waitForPromises();
          expect(stateQueryHandler).toHaveBeenCalledTimes(2);
        });

        it('refetches when the `mr-widget-rebase-success` event is emitted', async () => {
          expect(stateQueryHandler).toHaveBeenCalledTimes(1);
          eventHub.$emit('mr-widget-rebase-success', () => {});
          await waitForPromises();
          expect(stateQueryHandler).toHaveBeenCalledTimes(2);
        });

        it('should bind to `set-branch-remove-flag`', () => {
          expect(findPipelineContainer().props('mr')).toMatchObject({
            isRemovingSourceBranch: false,
          });
          eventHub.$emit('set-branch-remove-flag', [true]);
          expect(findPipelineContainer().props('mr')).toMatchObject({
            isRemovingSourceBranch: true,
          });
        });

        it('should bind to `failed-to-merge`', async () => {
          expect(findAlertMessage().exists()).toBe(false);
          const props = findPipelineContainer().props('mr');
          expect(props.state).toBe('merged');
          // Due to Vue 2 and 3 differences in handling props we must check for both undefined and null
          expect(props.mergeError == null).toBe(true);
          const mergeError = 'Something bad happened!';
          await eventHub.$emit('failed-to-merge', mergeError);

          expect(findAlertMessage().exists()).toBe(true);
          expect(findAlertMessage().text()).toBe(`${mergeError}. Try again.`);
          expect(findPipelineContainer().props('mr')).toMatchObject({ mergeError });
        });

        it('should bind to UpdateWidgetData', () => {
          const data = { ...mockData };
          eventHub.$emit('UpdateWidgetData', data);

          expect(mockSetData).toHaveBeenCalledWith(data);
        });
      });

      describe('setFavicon', () => {
        let faviconElement;

        beforeEach(() => {
          const favicon = document.createElement('link');
          favicon.setAttribute('id', 'favicon');
          favicon.dataset.originalHref = faviconDataUrl;
          document.body.appendChild(favicon);

          faviconElement = document.getElementById('favicon');
        });

        afterEach(() => {
          document.body.removeChild(document.getElementById('favicon'));
        });

        it('should call setFavicon method', async () => {
          await createComponent({ updatedMrData: { favicon_overlay_path: overlayDataUrl } });
          expect(setFaviconOverlay).toHaveBeenCalledWith(overlayDataUrl);
        });

        it('should not call setFavicon when there is no faviconOverlayPath', async () => {
          await createComponent({ updatedMrData: { favicon_overlay_path: null } });
          expect(faviconElement.getAttribute('href')).toEqual(null);
        });
      });

      describe('handleNotification', () => {
        const updatedMrData = { gitlabLogo: 'logo.png' };
        beforeEach(() => {
          jest.spyOn(notify, 'notifyMe').mockImplementation(() => {});
        });

        describe('when pipeline has passed', () => {
          beforeEach(() => {
            mock
              .onGet(mockData.merge_request_widget_path)
              .reply(HTTP_STATUS_OK, { ...mockData, ...updatedMrData, ci_status: 'failed' });
            mock
              .onGet(mockData.merge_request_cached_widget_path)
              .reply(HTTP_STATUS_OK, { ...mockData, ...updatedMrData, ci_status: 'failed' });
          });

          it('should call notifyMe', async () => {
            await createComponent({ updatedMrData });
            expect(notify.notifyMe).toHaveBeenCalledWith(
              `Pipeline passed`,
              `Pipeline passed for "${mockData.title}"`,
              updatedMrData.gitlabLogo,
            );
          });
        });

        describe('when pipeline has not passed', () => {
          it('should not call notifyMe if the status has not changed', async () => {
            await createComponent({ updatedMrData: { ci_status: undefined } });
            await eventHub.$emit('mr-widget-update-requested');
            expect(notify.notifyMe).not.toHaveBeenCalled();
          });

          it('should not notify if no pipeline provided', async () => {
            await createComponent({ updatedMrData: { pipeline: undefined } });
            expect(notify.notifyMe).not.toHaveBeenCalled();
          });
        });
      });

      describe('Apollo query', () => {
        const interval = 5000;
        const data = 'foo';
        const mockCheckStatus = jest.fn().mockResolvedValue({ data });
        const mockSetGraphqlData = jest.fn();
        const mockSetData = jest.fn();

        describe('when request is successful', () => {
          beforeEach(() => {
            wrapper.destroy();

            return createComponent({
              options: {},
              data: {
                pollInterval: interval,
                startingPollInterval: interval,
                mr: {
                  setData: mockSetData,
                  setGraphqlData: mockSetGraphqlData,
                  setGraphqlSubscriptionData: jest.fn(),
                },
                service: {
                  checkStatus: mockCheckStatus,
                },
              },
            });
          });

          describe('normal polling behavior', () => {
            it('responds to the GraphQL query finishing', () => {
              delete queryResponse.data.project.mergeTrains;
              delete queryResponse.data.project.mergeRequest.mergeTrainCar;
              delete queryResponse.data.project.mergeRequest.detailedMergeStatus;
              delete queryResponse.data.project.mergeRequest.commitCount;

              expect(mockSetGraphqlData).toHaveBeenCalledWith(
                expect.objectContaining({
                  ...queryResponse.data.project,
                  mergeRequest: expect.objectContaining({
                    ...queryResponse.data.project.mergeRequest,
                  }),
                }),
              );
              expect(stateQueryHandler).toHaveBeenCalledTimes(1);
            });
          });
        });

        describe('when request fails', () => {
          beforeEach(() => {
            wrapper.destroy();

            stateQueryHandler = jest.fn().mockRejectedValueOnce({ errors: [] });

            return createComponent({
              options: {},
              data: {
                pollInterval: interval,
                startingPollInterval: interval,
                mr: {
                  setData: mockSetData,
                  setGraphqlData: mockSetGraphqlData,
                  setGraphqlSubscriptionData: jest.fn(),
                },
                service: {
                  checkStatus: mockCheckStatus,
                },
              },
            });
          });

          it('stops polling', () => {
            expect(stateQueryHandler).toHaveBeenCalledTimes(1);

            jest.advanceTimersByTime(20);

            expect(stateQueryHandler).toHaveBeenCalledTimes(1);
          });
        });
      });
    });

    describe('rendering deployments', () => {
      it('renders multiple deployments', async () => {
        await createComponent({
          updatedMrData: {
            deployments: [
              mockDeployment,
              {
                ...mockDeployment,
                id: mockDeployment.id + 1,
              },
            ],
          },
        });
        expect(findPipelineContainer().props('isPostMerge')).toBe(false);
        expect(findPipelineContainer().props('mr').deployments).toHaveLength(2);
        expect(findPipelineContainer().props('mr').postMergeDeployments).toHaveLength(0);
      });
    });

    describe('pipeline for target branch after merge', () => {
      describe('with information for target branch pipeline', () => {
        const state = 'merged';

        it('renders pipeline block', async () => {
          await createComponent({ updatedMrData: { state, merge_pipeline: mockMergePipeline } });
          expect(findMergedPipelineContainer().exists()).toBe(true);
        });

        describe('with post merge deployments', () => {
          it('renders post deployment information', async () => {
            await createComponent({
              updatedMrData: {
                state,
                merge_pipeline: mockMergePipeline,
                post_merge_deployments: mockPostMergeDeployments,
              },
            });
            expect(findMergedPipelineContainer().exists()).toBe(true);
          });
        });
      });

      describe('without information for target branch pipeline', () => {
        it('does not render pipeline block', async () => {
          await createComponent({ updatedMrData: { merge_pipeline: undefined } });
          expect(findMergedPipelineContainer().exists()).toBe(false);
        });
      });

      describe('when state is not merged', () => {
        it('does not render pipeline block', async () => {
          await createComponent({ updatedMrData: { state: 'archived' } });
          expect(findMergedPipelineContainer().exists()).toBe(false);
        });
      });
    });
  });

  describe('merge error', () => {
    it.each`
      state       | show     | showText
      ${'closed'} | ${false} | ${'hides'}
      ${'merged'} | ${true}  | ${'shows'}
      ${'open'}   | ${true}  | ${'shows'}
    `('$showText merge error when state is $state', async ({ state, show }) => {
      createComponent({ updatedMrData: { state, mergeError: 'Error!' } });

      await waitForPromises();

      expect(findMergeError().exists()).toBe(show);
    });

    it('prevents XSS attacks by rendering merge error as plain text', async () => {
      const maliciousError = '<div class="xss"><script>alert("XSS")</script></div>';
      createComponent();

      await waitForPromises();
      eventHub.$emit('failed-to-merge', maliciousError);
      await nextTick();

      expect(findMergeError().text()).toContain(maliciousError);
      expect(findMergeError().element.querySelector('.xss')).toBe(null);
    });
  });

  describe('widget container', () => {
    it('renders the widget container when there is MR data', async () => {
      await createComponent(mockData);
      expect(findWidgetContainer().props('mr')).not.toBeUndefined();
    });
  });

  describe('async preparation for a newly opened MR', () => {
    beforeEach(() => {
      mock
        .onGet(mockData.merge_request_widget_path)
        .reply(() => [HTTP_STATUS_OK, { ...mockData, state: 'opened' }]);
    });

    it('does not render the Preparing state component by default', async () => {
      await createComponent({ mountFn: mountExtended });

      expect(findApprovalsWidget().exists()).toBe(true);
      expect(findPreparingWidget().exists()).toBe(false);
    });

    it('renders the Preparing state component when the MR state is initially "preparing"', async () => {
      await createComponent({
        updatedMrData: { state: 'opened', detailedMergeStatus: 'PREPARING' },
      });

      expect(findApprovalsWidget().exists()).toBe(false);
      expect(findPreparingWidget().exists()).toBe(true);
    });

    describe('when the MR is updated by observing its status', () => {
      beforeEach(() => {
        window.gon.features.realtimeMrStatusChange = true;
      });

      it("shows the Preparing widget when the MR reports it's not ready yet", async () => {
        await createComponent({
          updatedMrData: { state: 'opened', detailedMergeStatus: 'PREPARING' },
          options: {},
          data: {},
        });

        expect(wrapper.html()).toContain('mr-widget-preparing-stub');
      });

      it('removes the Preparing widget when the MR indicates it has been prepared', async () => {
        const stateSubscriptions = [];
        const stateSubscriptionHandler = () => {
          const sub = createMockApolloSubscription();
          stateSubscriptions.push(sub);
          return sub;
        };

        await createComponent({
          updatedMrData: { state: 'opened', detailedMergeStatus: 'PREPARING' },
          options: {},
          data: {},
          stateSubscriptionHandler,
        });

        expect(wrapper.html()).toContain('mr-widget-preparing-stub');

        stateSubscriptions.forEach((stateSubscription) => {
          stateSubscription.next({
            data: {
              mergeRequestMergeStatusUpdated: {
                detailedMergeStatus: 'MERGEABLE',
              },
            },
          });
        });

        // Wait for batched DOM updates
        await waitForPromises();

        expect(wrapper.html()).not.toContain('mr-widget-preparing-stub');
      });
    });
  });

  it('calls getState GraphQL query with target branches variable', async () => {
    createComponent();

    await waitForPromises();

    expect(stateQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        targetBranches: ['main'],
      }),
    );
  });
});
