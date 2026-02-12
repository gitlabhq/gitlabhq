import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import { createMockSubscription as createMockApolloSubscription } from 'mock-apollo-client';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import stubChildren from 'helpers/stub_children';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Reviewers from '~/sidebar/components/reviewers/reviewers.vue';
import SidebarReviewers from '~/sidebar/components/reviewers/sidebar_reviewers.vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import diffsEventHub from '~/diffs/event_hub';
import { useBatchComments } from '~/batch_comments/store';
import { sidebarState } from '~/sidebar/sidebar_state';
import getMergeRequestReviewersQuery from '~/sidebar/queries/get_merge_request_reviewers.query.graphql';
import mergeRequestReviewersUpdatedSubscription from '~/sidebar/queries/merge_request_reviewers.subscription.graphql';
import Mock from '../../mock_data';

jest.mock('~/super_sidebar/user_counts_fetch');

const { bindInternalEventDocument } = useMockInternalEventsTracking();
Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

const resetState = () => {
  Object.assign(sidebarState, {
    issuable: {},
    loading: false,
    initialLoading: true,
    drawerOpen: false,
  });
};

const resetSingletons = () => {
  SidebarService.singleton = null;
  SidebarStore.singleton = null;
  SidebarMediator.singleton = null;
};

describe('sidebar reviewers', () => {
  const apolloMock = createMockApollo();
  let wrapper;
  let mediator;
  let axiosMock;
  let trackEventSpy;
  let pinia;

  const findAssignButton = () => wrapper.findByTestId('sidebar-reviewers-assign-button');
  const findReviewers = () => wrapper.findComponent(Reviewers);

  const createComponent = ({ props, stubs, data } = {}) => {
    wrapper = shallowMountExtended(SidebarReviewers, {
      apolloProvider: apolloMock,
      pinia,
      propsData: {
        issuableIid: '1',
        issuableId: 1,
        mediator,
        field: '',
        projectPath: 'projectPath',
        changing: false,
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      provide: {
        projectPath: 'projectPath',
        issuableId: 1,
        issuableIid: 1,
        multipleApprovalRulesAvailable: false,
      },
      stubs: {
        ApprovalSummary: true,
        ...stubs,
      },
      // Attaching to document is required because this component emits something from the parent element :/
      attachTo: document.body,
    });

    ({ trackEventSpy } = bindInternalEventDocument(wrapper.element));
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
    axiosMock = new AxiosMockAdapter(axios);
    mediator = new SidebarMediator(Mock.mediator);

    jest.spyOn(mediator, 'saveReviewers').mockResolvedValue({});
    jest.spyOn(mediator, 'addSelfReview');
  });

  afterEach(() => {
    resetSingletons();
    axiosMock.restore();
  });

  it.each`
    copy               | canUpdate | expected
    ${'shows'}         | ${true}   | ${true}
    ${'does not show'} | ${false}  | ${false}
  `('$copy Assign button when canUpdate is $canUpdate', ({ canUpdate, expected }) => {
    createComponent({
      data: {
        issuable: { userPermissions: { adminMergeRequest: canUpdate } },
      },
    });

    expect(findAssignButton().exists()).toBe(expected);
  });

  it('calls the mediator when it saves the reviewers', () => {
    createComponent();

    expect(mediator.saveReviewers).not.toHaveBeenCalled();

    wrapper.vm.saveReviewers();

    expect(mediator.saveReviewers).toHaveBeenCalled();
  });

  it('re-fetches user counts after saving reviewers', async () => {
    createComponent();

    expect(fetchUserCounts).not.toHaveBeenCalled();

    wrapper.vm.saveReviewers();
    await nextTick();

    expect(fetchUserCounts).toHaveBeenCalled();
  });

  describe('assign yourself', () => {
    it('tracks how many times the Reviewers component indicates the user is assigning themself', async () => {
      createComponent({
        data: {
          issuable: { userPermissions: { adminMergeRequest: true } },
        },
        stubs: {
          Reviewers,
        },
      });

      // Wait for Apollo to finish so the sidebar is enabled
      await nextTick();

      const reviewers = findReviewers();
      reviewers.vm.assignSelf();

      expect(trackEventSpy).toHaveBeenCalledWith('assign_self_as_reviewer_in_mr', {}, undefined);
    });

    it('calls the mediator when "reviewBySelf" method is called', () => {
      createComponent();

      expect(mediator.addSelfReview).not.toHaveBeenCalled();
      expect(mediator.store.reviewers).toHaveLength(0);

      wrapper.vm.reviewBySelf();

      expect(mediator.addSelfReview).toHaveBeenCalled();
      expect(mediator.store.reviewers).toHaveLength(1);
    });
  });
});

describe('sidebar reviewers approval tracking', () => {
  const mockReviewersResponse = (username = 'root') => ({
    data: {
      namespace: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/1',
        issuable: {
          __typename: 'MergeRequest',
          id: 'gid://gitlab/MergeRequest/1',
          reviewers: {
            __typename: 'MergeRequestReviewerConnection',
            nodes: [
              {
                __typename: 'MergeRequestReviewer',
                id: 'gid://gitlab/User/1',
                avatarUrl: 'https://example.com/avatar.png',
                name: 'Test User',
                username,
                webUrl: 'https://example.com/root',
                webPath: '/root',
                status: null,
                type: 'human',
                mergeRequestInteraction: {
                  __typename: 'UserMergeRequestInteraction',
                  canMerge: true,
                  canUpdate: true,
                  approved: true,
                  reviewState: 'APPROVED',
                  applicableApprovalRules: [],
                },
              },
            ],
          },
          userPermissions: {
            __typename: 'MergeRequestPermissions',
            adminMergeRequest: true,
          },
        },
      },
    },
  });

  let wrapper;
  let mediator;
  let axiosMock;
  let pinia;
  let trackEventSpy;
  let apolloProvider;

  beforeEach(() => {
    resetSingletons();
    resetState();

    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    resetSingletons();
    axiosMock.restore();
  });

  it.each`
    desc                        | reviewerUsername | expectedReviewer
    ${'user is a reviewer'}     | ${'root'}        | ${true}
    ${'user is not a reviewer'} | ${'other-user'}  | ${false}
  `(
    'tracks approval event with reviewer=$expectedReviewer when $desc',
    async ({ reviewerUsername, expectedReviewer }) => {
      const queryHandler = jest.fn().mockResolvedValue(mockReviewersResponse(reviewerUsername));
      const subscriptionHandler = createMockApolloSubscription();

      apolloProvider = createMockApollo([[getMergeRequestReviewersQuery, queryHandler]]);
      apolloProvider.defaultClient.setRequestHandler(
        mergeRequestReviewersUpdatedSubscription,
        () => subscriptionHandler,
      );

      mediator = new SidebarMediator({ currentUser: { username: 'root' } });

      wrapper = mountExtended(SidebarReviewers, {
        apolloProvider,
        pinia,
        propsData: {
          issuableIid: '1',
          issuableId: 1,
          mediator,
          field: '',
          projectPath: 'projectPath',
          changing: false,
        },
        provide: {
          projectPath: 'projectPath',
          issuableId: 1,
          issuableIid: 1,
          multipleApprovalRulesAvailable: false,
        },
        stubs: {
          ...stubChildren(SidebarReviewers),
          GlButton: false,
        },
        attachTo: document.body,
      });

      ({ trackEventSpy } = bindInternalEventDocument(wrapper.element));

      await waitForPromises();

      diffsEventHub.$emit('mr:reviewDrawer:submit:approval', {
        summary: true,
        comments: 2,
      });

      await nextTick();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'mr_approved_from_review_drawer',
        {
          reviewer: expectedReviewer,
          drafts: 2,
          summary: true,
        },
        undefined,
      );
    },
  );
});
