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
import { STATE_QUERY_POLLING_INTERVAL_BACKOFF } from '~/vue_merge_request_widget/constants';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import Preparing from '~/vue_merge_request_widget/components/states/mr_widget_preparing.vue';
import ShaMismatch from '~/vue_merge_request_widget/components/states/sha_mismatch.vue';
import MergedState from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import WidgetContainer from '~/vue_merge_request_widget/components/widget/app.vue';
import WidgetSuggestPipeline from '~/vue_merge_request_widget/components/mr_widget_suggest_pipeline.vue';
import MrWidgetAlertMessage from '~/vue_merge_request_widget/components/mr_widget_alert_message.vue';
import getStateQuery from '~/vue_merge_request_widget/queries/get_state.query.graphql';
import getStateSubscription from '~/vue_merge_request_widget/queries/get_state.subscription.graphql';
import readyToMergeSubscription from '~/vue_merge_request_widget/queries/states/ready_to_merge.subscription.graphql';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_merge_request_widget/widgets/security_reports/graphql/security_report_merge_request_download_paths.query.graphql';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import approvalsQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import approvedBySubscription from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.subscription.graphql';
import userPermissionsQuery from '~/vue_merge_request_widget/queries/permissions.query.graphql';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';
import mergeChecksQuery from '~/vue_merge_request_widget/queries/merge_checks.query.graphql';
import mergeChecksSubscription from '~/vue_merge_request_widget/queries/merge_checks.subscription.graphql';
import userPermissionsReviewerQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';

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
          mergeRequest: {
            ...getStateQueryResponse.data.project.mergeRequest,
            mergeError: mrData.mergeError || null,
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
              mergeRequest: { id: 1, userPermissions: { adminMergeRequest: false } },
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
      ...(options.apolloMock || []),
    ];
    const subscriptionHandlers = [
      [approvedBySubscription, () => mockedApprovalsSubscription],
      [getStateSubscription, stateSubscriptionHandler],
      [readyToMergeSubscription, () => createMockApolloSubscription()],
      [mergeChecksSubscription, () => createMockApolloSubscription()],
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
  const findPipelineContainer = () => wrapper.findByTestId('pipeline-container');
  const findAlertMessage = () => wrapper.findComponent(MrWidgetAlertMessage);
  const findMergePipelineForkAlert = () => wrapper.findByTestId('merge-pipeline-fork-warning');
  const findSuggestPipeline = () => wrapper.findComponent(WidgetSuggestPipeline);
  const findWidgetContainer = () => wrapper.findComponent(WidgetContainer);

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
            mergePipelinesEnabled: true,
          };

          await nextTick();
          expect(findMergePipelineForkAlert().exists()).toBe(true);
        });
      });

      describe('formattedHumanAccess', () => {
        it('renders empty string when user is a tool admin but not a member of project', () => {
          createComponent({
            updatedMrData: {
              human_access: null,
              merge_request_add_ci_config_path: 'test',
              has_ci: false,
              is_dismissed_suggest_pipeline: false,
            },
          });
          expect(findSuggestPipeline().props('humanAccess')).toBe('');
        });
        it('renders human access when user is a member of the project', () => {
          createComponent({
            updatedMrData: {
              human_access: 'Owner',
              merge_request_add_ci_config_path: 'test',
              has_ci: false,
              is_dismissed_suggest_pipeline: false,
            },
          });
          expect(findSuggestPipeline().props('humanAccess')).toBe('owner');
        });
      });
    });

    describe('methods', () => {
      describe('checkStatus', () => {
        const updatedMrData = { foo: 1 };
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
          eventHub.$emit('MRWidgetUpdateRequested', callback);
          await waitForPromises();
          expect(callback).toHaveBeenCalledWith(expect.objectContaining(updatedMrData));
        });

        it('notifies the user of the pipeline status', async () => {
          jest.spyOn(notify, 'notifyMe').mockImplementation(() => {});
          const logoFilename = 'logo.png';
          await createComponent({
            updatedMrData: { gitlabLogo: logoFilename, ci_status: 'failed' },
          });
          eventHub.$emit('MRWidgetUpdateRequested');
          await waitForPromises();
          expect(notify.notifyMe).toHaveBeenCalledWith(
            `Pipeline passed`,
            `Pipeline passed for "${mockData.title}"`,
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
          eventHub.$emit('MRWidgetUpdateRequested');
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
          eventHub.$emit('FetchDeployments', {});
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
          eventHub.$emit('FetchActionsContent');
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

        it('refetches when "MRWidgetUpdateRequested" event is emitted', async () => {
          expect(stateQueryHandler).toHaveBeenCalledTimes(1);
          eventHub.$emit('MRWidgetUpdateRequested', () => {});
          await waitForPromises();
          expect(stateQueryHandler).toHaveBeenCalledTimes(2);
        });

        it('refetches when "MRWidgetRebaseSuccess" event is emitted', async () => {
          expect(stateQueryHandler).toHaveBeenCalledTimes(1);
          eventHub.$emit('MRWidgetRebaseSuccess', () => {});
          await waitForPromises();
          expect(stateQueryHandler).toHaveBeenCalledTimes(2);
        });

        it('should bind to SetBranchRemoveFlag', () => {
          expect(findPipelineContainer().props('mr')).toMatchObject({
            isRemovingSourceBranch: false,
          });
          eventHub.$emit('SetBranchRemoveFlag', [true]);
          expect(findPipelineContainer().props('mr')).toMatchObject({
            isRemovingSourceBranch: true,
          });
        });

        it('should bind to FailedToMerge', async () => {
          expect(findAlertMessage().exists()).toBe(false);
          const props = findPipelineContainer().props('mr');
          expect(props.state).toBe('merged');
          // Due to Vue 2 and 3 differences in handling props we must check for both undefined and null
          expect(props.mergeError == null).toBe(true);
          const mergeError = 'Something bad happened!';
          await eventHub.$emit('FailedToMerge', mergeError);

          expect(findAlertMessage().exists()).toBe(true);
          expect(findAlertMessage().text()).toBe(`${mergeError}. Try again.`);
          expect(findPipelineContainer().props('mr')).toMatchObject({
            mergeError,
            state: 'failedToMerge',
          });
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
            await eventHub.$emit('MRWidgetUpdateRequested');
            expect(notify.notifyMe).not.toHaveBeenCalled();
          });

          it('should not notify if no pipeline provided', async () => {
            await createComponent({ updatedMrData: { pipeline: undefined } });
            expect(notify.notifyMe).not.toHaveBeenCalled();
          });
        });
      });

      describe('Apollo query', () => {
        const interval = 5;
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
              expect(mockSetGraphqlData).toHaveBeenCalledWith(queryResponse.data.project);
              expect(mockCheckStatus).toHaveBeenCalled();
              expect(mockSetData).toHaveBeenCalledWith(data, undefined);
              expect(stateQueryHandler).toHaveBeenCalledTimes(1);
            });
          });

          describe('external event control', () => {
            describe('enablePolling', () => {
              it('enables the Apollo query polling using the event hub', () => {
                eventHub.$emit('EnablePolling');

                expect(stateQueryHandler).toHaveBeenCalled();
                jest.advanceTimersByTime(interval * STATE_QUERY_POLLING_INTERVAL_BACKOFF);
                expect(stateQueryHandler).toHaveBeenCalledTimes(2);
              });
            });

            describe('disablePolling', () => {
              it('disables the Apollo query polling using the event hub', () => {
                expect(stateQueryHandler).toHaveBeenCalledTimes(1);

                eventHub.$emit('DisablePolling');
                jest.advanceTimersByTime(interval * STATE_QUERY_POLLING_INTERVAL_BACKOFF);

                expect(stateQueryHandler).toHaveBeenCalledTimes(1); // no additional polling after a real interval timeout
              });
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

    it('should not suggest pipelines when feature flag is not present', () => {
      createComponent();
      expect(findSuggestPipeline().exists()).toBe(false);
    });
  });

  describe('suggestPipeline', () => {
    beforeEach(() => {
      mock.onAny().reply(HTTP_STATUS_OK);
    });

    describe('given feature flag is enabled', () => {
      it('should suggest pipelines when none exist', async () => {
        await createComponent({ updatedMrData: { has_ci: false } });
        expect(findSuggestPipeline().exists()).toBe(true);
      });

      it.each([
        { is_dismissed_suggest_pipeline: true },
        { merge_request_add_ci_config_path: null },
        { has_ci: true },
      ])('with %s, should not suggest pipeline', async (obj) => {
        await createComponent({ updatedMrData: { has_ci: false, ...obj } });

        expect(findSuggestPipeline().exists()).toBe(false);
      });

      it('should allow dismiss of the suggest pipeline message', async () => {
        await createComponent({ updatedMrData: { has_ci: false } });
        await findSuggestPipeline().vm.$emit('dismiss');

        expect(findSuggestPipeline().exists()).toBe(false);
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

      expect(wrapper.findByTestId('merge-error').exists()).toBe(show);
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
        const stateSubscription = createMockApolloSubscription();

        await createComponent({
          updatedMrData: { state: 'opened', detailedMergeStatus: 'PREPARING' },
          options: {},
          data: {},
          stateSubscriptionHandler: () => stateSubscription,
        });

        expect(wrapper.html()).toContain('mr-widget-preparing-stub');

        stateSubscription.next({
          data: {
            mergeRequestMergeStatusUpdated: {
              preparedAt: 'non-null value',
            },
          },
        });

        // Wait for batched DOM updates
        await nextTick();

        expect(wrapper.html()).not.toContain('mr-widget-preparing-stub');
      });
    });
  });
});
