import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockSubscription as createMockApolloSubscription } from 'mock-apollo-client';
import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import ApprovalsSummary from '~/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import ApprovalsSummaryOptional from '~/vue_merge_request_widget/components/approvals/approvals_summary_optional.vue';
import {
  APPROVE_ERROR,
  UNAPPROVE_ERROR,
} from '~/vue_merge_request_widget/components/approvals/messages';
import eventHub from '~/vue_merge_request_widget/event_hub';
import approvedByQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import approvedBySubscription from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.subscription.graphql';
import { createCanApproveResponse } from 'jest/approvals/mock_data';

Vue.use(VueApollo);

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

const TEST_HELP_PATH = 'help/path';
const testApprovedBy = () => [1, 7, 10].map((id) => ({ id }));
const testApprovals = () => ({
  approved: false,
  approved_by: testApprovedBy().map((user) => ({ user })),
  approval_rules_left: [],
  approvals_left: 4,
  suggested_approvers: [],
  user_can_approve: true,
  user_has_approved: true,
  require_password_to_approve: false,
  invalid_approvers_rules: [],
});

describe('MRWidget approvals', () => {
  let mockedSubscription;
  let wrapper;
  let service;
  let mr;

  const createComponent = (options = {}, responses = { query: approvedByCurrentUser }) => {
    mockedSubscription = createMockApolloSubscription();

    const requestHandlers = [[approvedByQuery, jest.fn().mockResolvedValue(responses.query)]];
    const subscriptionHandlers = [[approvedBySubscription, () => mockedSubscription]];
    const apolloProvider = createMockApollo(requestHandlers);
    const provide = {
      ...options.provide,
      glFeatures: {
        realtimeApprovals: options.provide?.glFeatures?.realtimeApprovals || false,
      },
    };

    subscriptionHandlers.forEach(([document, stream]) => {
      apolloProvider.defaultClient.setRequestHandler(document, stream);
    });

    wrapper = shallowMount(Approvals, {
      apolloProvider,
      propsData: {
        mr,
        service,
        ...options.props,
      },
      provide,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAction = () => wrapper.findComponent(GlButton);
  const findActionData = () => {
    const action = findAction();

    return !action.exists()
      ? null
      : {
          variant: action.props('variant'),
          category: action.props('category'),
          text: action.text(),
        };
  };
  const findSummary = () => wrapper.findComponent(ApprovalsSummary);
  const findOptionalSummary = () => wrapper.findComponent(ApprovalsSummaryOptional);

  beforeEach(() => {
    service = {
      ...{
        approveMergeRequest: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
        unapproveMergeRequest: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
        approveMergeRequestWithAuth: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
      },
    };
    mr = {
      ...{
        setApprovals: jest.fn(),
        setApprovalRules: jest.fn(),
      },
      approvalsHelpPath: TEST_HELP_PATH,
      approvals: testApprovals(),
      approvalRules: [],
      isOpen: true,
      state: 'open',
      targetProjectFullPath: 'gitlab-org/gitlab',
      id: 1,
      iid: '1',
    };

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    gon.current_user_id = getIdFromGraphQLId(
      approvedByCurrentUser.data.project.mergeRequest.approvedBy.nodes[0].id,
    );
  });

  describe('action button', () => {
    describe('when mr is closed', () => {
      beforeEach(async () => {
        const response = createCanApproveResponse();

        mr.isOpen = false;

        createComponent({}, { query: response });
        await waitForPromises();
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user cannot approve', () => {
      beforeEach(async () => {
        const response = JSON.parse(JSON.stringify(approvedByCurrentUser));
        response.data.project.mergeRequest.approvedBy.nodes = [];

        createComponent({}, { query: response });
        await waitForPromises();
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user can approve', () => {
      let canApproveResponse;

      beforeEach(() => {
        canApproveResponse = createCanApproveResponse();
      });

      describe('and MR is unapproved', () => {
        beforeEach(async () => {
          createComponent({}, { query: canApproveResponse });
          await waitForPromises();
        });

        it('approve action is rendered', () => {
          expect(findActionData()).toEqual({
            variant: 'confirm',
            text: 'Approve',
            category: 'primary',
          });
        });
      });

      describe('and MR is approved', () => {
        beforeEach(() => {
          canApproveResponse.data.project.mergeRequest.approved = true;
        });

        describe('with no approvers', () => {
          beforeEach(async () => {
            canApproveResponse.data.project.mergeRequest.approvedBy.nodes = [];
            createComponent({}, { query: canApproveResponse });
            await nextTick();
          });

          it('approve action is rendered', () => {
            expect(findActionData()).toMatchObject({
              variant: 'confirm',
              text: 'Approve',
            });
          });
        });

        describe('with approvers', () => {
          beforeEach(async () => {
            canApproveResponse.data.project.mergeRequest.approvedBy.nodes =
              approvedByCurrentUser.data.project.mergeRequest.approvedBy.nodes;

            canApproveResponse.data.project.mergeRequest.approvedBy.nodes[0].id = 2;

            createComponent({}, { query: canApproveResponse });
            await waitForPromises();
          });

          it('approve additionally action is rendered', () => {
            expect(findActionData()).toEqual({
              variant: 'confirm',
              text: 'Approve additionally',
              category: 'secondary',
            });
          });
        });
      });

      describe('when approve action is clicked', () => {
        beforeEach(async () => {
          createComponent({}, { query: canApproveResponse });
          await waitForPromises();
        });

        it('shows loading icon', () => {
          jest.spyOn(service, 'approveMergeRequest').mockReturnValue(new Promise(() => {}));
          const action = findAction();

          expect(action.props('loading')).toBe(false);

          action.vm.$emit('click');

          return nextTick().then(() => {
            expect(action.props('loading')).toBe(true);
          });
        });

        describe('and after loading', () => {
          beforeEach(() => {
            findAction().vm.$emit('click');
            return nextTick();
          });

          it('calls service approve', () => {
            expect(service.approveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });
        });

        describe('and error', () => {
          beforeEach(() => {
            jest.spyOn(service, 'approveMergeRequest').mockReturnValue(Promise.reject());
            findAction().vm.$emit('click');
            return nextTick();
          });

          it('shows an alert with error message', () => {
            expect(createAlert).toHaveBeenCalledWith({ message: APPROVE_ERROR });
          });

          it('clears the previous alert', () => {
            expect(mockAlertDismiss).toHaveBeenCalledTimes(0);

            findAction().vm.$emit('click');
            expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
          });
        });
      });
    });

    describe('when user has approved', () => {
      beforeEach(async () => {
        const response = JSON.parse(JSON.stringify(approvedByCurrentUser));

        createComponent({}, { query: response });

        await waitForPromises();
      });

      it('revoke action is rendered', () => {
        expect(findActionData()).toEqual({
          category: 'primary',
          variant: 'default',
          text: 'Revoke approval',
        });
      });

      describe('when revoke action is clicked', () => {
        describe('and successful', () => {
          beforeEach(() => {
            findAction().vm.$emit('click');
            return nextTick();
          });

          it('calls service unapprove', () => {
            expect(service.unapproveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });
        });

        describe('and error', () => {
          beforeEach(() => {
            jest.spyOn(service, 'unapproveMergeRequest').mockReturnValue(Promise.reject());
            findAction().vm.$emit('click');
            return nextTick();
          });

          it('alerts error message', () => {
            expect(createAlert).toHaveBeenCalledWith({ message: UNAPPROVE_ERROR });
          });
        });
      });
    });
  });

  describe('approvals optional summary', () => {
    let optionalApprovalsResponse;

    beforeEach(() => {
      optionalApprovalsResponse = JSON.parse(JSON.stringify(approvedByCurrentUser));
    });

    describe('when no approvals required and no approvers', () => {
      beforeEach(() => {
        optionalApprovalsResponse.data.project.mergeRequest.approvedBy.nodes = [];
        optionalApprovalsResponse.data.project.mergeRequest.approvalsRequired = 0;
      });

      describe('and can approve', () => {
        beforeEach(async () => {
          optionalApprovalsResponse.data.project.mergeRequest.userPermissions.canApprove = true;

          createComponent({}, { query: optionalApprovalsResponse });
          await waitForPromises();
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: true,
            helpPath: TEST_HELP_PATH,
          });
        });
      });

      describe('and cannot approve', () => {
        beforeEach(async () => {
          createComponent({}, { query: optionalApprovalsResponse });
          await nextTick();
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: false,
            helpPath: TEST_HELP_PATH,
          });
        });
      });
    });
  });

  describe('approvals summary', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('is rendered with props', () => {
      const summary = findSummary();

      expect(findOptionalSummary().exists()).toBe(false);
      expect(summary.exists()).toBe(true);
      expect(summary.props()).toMatchObject({
        approvalState: approvedByCurrentUser.data.project.mergeRequest,
      });
    });
  });

  describe('realtime approvals update', () => {
    describe('realtime_approvals feature disabled', () => {
      beforeEach(() => {
        jest.spyOn(console, 'warn').mockImplementation();
        createComponent();
      });

      it('does not subscribe to the approvals update socket', () => {
        expect(mr.setApprovals).not.toHaveBeenCalled();
        mockedSubscription.next({});
        // eslint-disable-next-line no-console
        expect(console.warn).toHaveBeenCalledWith(
          expect.stringMatching('Mock subscription has no observer, this will have no effect'),
        );
        expect(mr.setApprovals).not.toHaveBeenCalled();
      });
    });

    describe('realtime_approvals feature enabled', () => {
      const subscriptionApproval = { approved: true };
      const subscriptionResponse = {
        data: { mergeRequestApprovalStateUpdated: subscriptionApproval },
      };

      beforeEach(() => {
        createComponent({
          provide: { glFeatures: { realtimeApprovals: true } },
        });
      });

      it('updates approvals when the subscription data is streamed to the Apollo client', () => {
        expect(mr.setApprovals).not.toHaveBeenCalled();

        mockedSubscription.next(subscriptionResponse);

        expect(mr.setApprovals).toHaveBeenCalledWith(subscriptionApproval);
      });
    });
  });
});
