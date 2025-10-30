import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import HomepageApp from '~/homepage/components/homepage_app.vue';
import PickUpWidget from '~/homepage/components/pick_up_widget.vue';
import FeedbackWidget from '~/homepage/components/feedback_widget.vue';
import BaseWidget from '~/homepage/components/base_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import mergeRequestsWidgetMetadataQuery from '~/homepage/graphql/queries/merge_requests_widget_metadata.query.graphql';
import workItemsWidgetMetadataQuery from '~/homepage/graphql/queries/work_items_widget_metadata.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_MERGE_REQUESTS,
  TRACKING_LABEL_WORK_ITEMS,
  TRACKING_PROPERTY_REVIEW_REQUESTED,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  TRACKING_PROPERTY_AUTHORED_BY_YOU,
} from '~/homepage/tracking_constants';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { lastPushEvent } from './mocks/last_push_event_mock';
import { mergeRequestsDataWithItems } from './mocks/merge_requests_widget_metadata_query_mocks';
import { workItemsDataWithItems } from './mocks/work_items_widget_metadata_query_mocks';

jest.mock('~/super_sidebar/user_counts_manager', () => ({
  userCounts: { assigned_issues: 0 },
  createUserCountsManager: jest.fn(),
  useCachedUserCounts: jest.fn(),
}));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/super_sidebar/user_counts_fetch');

describe('HomepageApp', () => {
  const MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH = '/merge/requests/review/requested/path';
  const MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_ERROR_TEXT =
    'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.';
  const MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_TEXT = 'Waiting for your review';
  const MOCK_ASSIGNED_MERGE_REQUESTS_PATH = '/merge/requests/assigned/to/you/path';
  const MOCK_ASSIGNED_MERGE_REQUESTS_ERROR_TEXT =
    'The number of merge requests is not available. Please refresh the page to try again, or visit the dashboard.';
  const MOCK_ASSIGNED_MERGE_REQUESTS_TEXT = 'Assigned to you';
  const MOCK_ASSIGNED_WORK_ITEMS_PATH = '/work/items/assigned/to/you/path';
  const MOCK_ASSIGNED_WORK_ITEMS_ERROR_TEXT =
    'The number of issues is not available. Please refresh the page to try again, or visit the issue list.';
  const MOCK_ASSIGNED_WORK_ITEMS_TEXT = 'Assigned to you';
  const MOCK_AUTHORED_WORK_ITEMS_PATH = '/work/items/authored/to/you/path';
  const MOCK_AUTHORED_WORK_ITEMS_ERROR_TEXT =
    'The number of issues is not available. Please refresh the page to try again, or visit the issue list.';
  const MOCK_AUTHORED_WORK_ITEMS_TEXT = 'Authored by you';
  const MOCK_ACTIVITY_PATH = '/activity/path';
  const MOCK_DUO_CODE_REVIEW_BOT_USERNAME = 'GitLabDuo';

  let wrapper;

  const findReviewRequestedWidget = () => wrapper.findByTestId('review-requested-widget');
  const findAssignedMergeRequestsWidget = () =>
    wrapper.findByTestId('assigned-merge-requests-widget');
  const findAssignedWorkItemsWidget = () => wrapper.findByTestId('assigned-work-items-widget');
  const findAuthoredWorkItemsWidget = () => wrapper.findByTestId('authored-work-items-widget');
  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findPickUpWidget = () => wrapper.findComponent(PickUpWidget);
  const findFeedbackWidget = () => wrapper.findComponent(FeedbackWidget);

  function createWrapper(props = {}) {
    wrapper = shallowMountExtended(HomepageApp, {
      provide: {
        duoCodeReviewBotUsername: MOCK_DUO_CODE_REVIEW_BOT_USERNAME,
      },
      propsData: {
        reviewRequestedPath: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
        assignedMergeRequestsPath: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
        assignedWorkItemsPath: MOCK_ASSIGNED_WORK_ITEMS_PATH,
        authoredWorkItemsPath: MOCK_AUTHORED_WORK_ITEMS_PATH,
        activityPath: MOCK_ACTIVITY_PATH,
        lastPushEvent,
        ...props,
      },
    });
  }

  const mergeRequestsWidgetMetadataQuerySuccessHandler = (data) =>
    jest.fn().mockResolvedValue(data);

  const workItemsWidgetMetadataQuerySuccessHandler = (data) => jest.fn().mockResolvedValue(data);

  function createApolloWrapper({
    mergeRequestsWidgetMetadataQueryHandler = mergeRequestsWidgetMetadataQuerySuccessHandler(
      mergeRequestsDataWithItems,
    ),
    workItemsWidgetMetadataQueryHandler = workItemsWidgetMetadataQuerySuccessHandler(
      workItemsDataWithItems,
    ),
    assignedWorkItemsCount = 5,
  } = {}) {
    userCounts.assigned_issues = assignedWorkItemsCount;

    const mockApollo = createMockApollo([
      [mergeRequestsWidgetMetadataQuery, mergeRequestsWidgetMetadataQueryHandler],
      [workItemsWidgetMetadataQuery, workItemsWidgetMetadataQueryHandler],
    ]);
    wrapper = shallowMountExtended(HomepageApp, {
      apolloProvider: mockApollo,
      provide: {
        duoCodeReviewBotUsername: MOCK_DUO_CODE_REVIEW_BOT_USERNAME,
      },
      propsData: {
        reviewRequestedPath: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
        assignedMergeRequestsPath: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
        assignedWorkItemsPath: MOCK_ASSIGNED_WORK_ITEMS_PATH,
        authoredWorkItemsPath: MOCK_AUTHORED_WORK_ITEMS_PATH,
        activityPath: MOCK_ACTIVITY_PATH,
        lastPushEvent,
      },
      stubs: {
        GlSprintf,
        BaseWidget,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    userCounts.assigned_issues = 0;
  });

  describe('userItemsCountWidgets', () => {
    Vue.use(VueApollo);

    beforeEach(() => {
      createApolloWrapper();
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('passes the correct props to the `review requested widget`', async () => {
      await waitForPromises();

      expect(findReviewRequestedWidget().props()).toEqual({
        errorText: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_ERROR_TEXT,
        hasError: false,
        cardText: 'Merge requests',
        linkText: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_TEXT,
        path: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
        userItems: mergeRequestsDataWithItems.data.currentUser.reviewRequestedMergeRequests,
        iconName: 'merge-request',
      });
    });

    it('passes the correct props to the `assigned merge requests widget`', async () => {
      await waitForPromises();

      expect(findAssignedMergeRequestsWidget().props()).toEqual({
        errorText: MOCK_ASSIGNED_MERGE_REQUESTS_ERROR_TEXT,
        hasError: false,
        cardText: 'Merge requests',
        linkText: MOCK_ASSIGNED_MERGE_REQUESTS_TEXT,
        path: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
        userItems: mergeRequestsDataWithItems.data.currentUser.assignedMergeRequests,
        iconName: 'merge-request',
      });
    });

    it('passes the correct props to the `assigned work items widget`', async () => {
      await waitForPromises();

      expect(findAssignedWorkItemsWidget().props()).toEqual({
        errorText: MOCK_ASSIGNED_WORK_ITEMS_ERROR_TEXT,
        hasError: false,
        cardText: 'Issues',
        linkText: MOCK_ASSIGNED_WORK_ITEMS_TEXT,
        path: MOCK_ASSIGNED_WORK_ITEMS_PATH,
        userItems: {
          ...workItemsDataWithItems.data.currentUser.assigned,
          count: 5,
        },
        iconName: 'work-item-issue',
      });
    });

    it('passes the correct props to the `authored work items widget`', async () => {
      await waitForPromises();

      expect(findAuthoredWorkItemsWidget().props()).toEqual({
        errorText: MOCK_AUTHORED_WORK_ITEMS_ERROR_TEXT,
        hasError: false,
        cardText: 'Issues',
        linkText: MOCK_AUTHORED_WORK_ITEMS_TEXT,
        path: MOCK_AUTHORED_WORK_ITEMS_PATH,
        userItems: workItemsDataWithItems.data.currentUser.authored,
        iconName: 'work-item-issue',
      });
    });

    it('passes null userItems to assigned work items widget when workItemsMetadata.assigned is null', async () => {
      const workItemsDataWithoutAssigned = {
        data: {
          currentUser: {
            assigned: null,
            authored: workItemsDataWithItems.data.currentUser.authored,
          },
        },
      };

      createApolloWrapper({
        workItemsWidgetMetadataQueryHandler: workItemsWidgetMetadataQuerySuccessHandler(
          workItemsDataWithoutAssigned,
        ),
      });

      await waitForPromises();

      expect(findAssignedWorkItemsWidget().props()).toEqual(
        expect.objectContaining({
          userItems: null,
        }),
      );
    });

    describe('query errors', () => {
      it('provides error to both merge request widgets, if the query errors out', async () => {
        createApolloWrapper({
          mergeRequestsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
        });

        await waitForPromises();

        expect(findReviewRequestedWidget().props()).toEqual(
          expect.objectContaining({
            hasError: true,
            userItems: null,
          }),
        );
        expect(findAssignedMergeRequestsWidget().props()).toEqual(
          expect.objectContaining({
            hasError: true,
            userItems: null,
          }),
        );
        expect(Sentry.captureException).toHaveBeenCalled();
      });

      it('provides error to both work item widgets, if the query errors out', async () => {
        createApolloWrapper({
          workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
        });

        await waitForPromises();

        expect(findAssignedWorkItemsWidget().props()).toEqual(
          expect.objectContaining({
            hasError: true,
            userItems: null,
          }),
        );
        expect(findAuthoredWorkItemsWidget().props()).toEqual(
          expect.objectContaining({
            hasError: true,
            userItems: null,
          }),
        );
        expect(Sentry.captureException).toHaveBeenCalled();
      });
    });

    describe('tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('tracks emit of review requested widget', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findReviewRequestedWidget().vm.$emit('click-link');

        expect(trackEventSpy).toHaveBeenCalledWith(
          EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
          {
            label: TRACKING_LABEL_MERGE_REQUESTS,
            property: TRACKING_PROPERTY_REVIEW_REQUESTED,
          },
          undefined,
        );
      });

      it('tracks emit of assigned merge requests widget', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findAssignedMergeRequestsWidget().vm.$emit('click-link');

        expect(trackEventSpy).toHaveBeenCalledWith(
          EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
          {
            label: TRACKING_LABEL_MERGE_REQUESTS,
            property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
          },
          undefined,
        );
      });

      it('tracks emit of assigned work items widget', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findAssignedWorkItemsWidget().vm.$emit('click-link');

        expect(trackEventSpy).toHaveBeenCalledWith(
          EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
          {
            label: TRACKING_LABEL_WORK_ITEMS,
            property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
          },
          undefined,
        );
      });

      it('tracks emit of authored work items widget', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findAuthoredWorkItemsWidget().vm.$emit('click-link');

        expect(trackEventSpy).toHaveBeenCalledWith(
          EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
          {
            label: TRACKING_LABEL_WORK_ITEMS,
            property: TRACKING_PROPERTY_AUTHORED_BY_YOU,
          },
          undefined,
        );
      });
    });

    describe('BaseWidget integration', () => {
      it('renders BaseWidget without styling', () => {
        const baseWidget = findBaseWidget();

        expect(baseWidget.exists()).toBe(true);
        expect(baseWidget.props('applyDefaultStyling')).toBe(false);
      });

      it('handles visible event from BaseWidget', async () => {
        const mergeRequestsHandler = jest.fn().mockResolvedValue(mergeRequestsDataWithItems);
        const workItemsHandler = jest.fn().mockResolvedValue(workItemsDataWithItems);

        createApolloWrapper({
          mergeRequestsWidgetMetadataQueryHandler: mergeRequestsHandler,
          workItemsWidgetMetadataQueryHandler: workItemsHandler,
        });

        await waitForPromises();

        // queried on initial mount
        expect(mergeRequestsHandler).toHaveBeenCalledTimes(1);
        expect(workItemsHandler).toHaveBeenCalledTimes(1);

        const baseWidget = findBaseWidget();
        baseWidget.vm.$emit('visible');

        await waitForPromises();

        // queried after visibility change
        expect(mergeRequestsHandler).toHaveBeenCalledTimes(2);
        expect(workItemsHandler).toHaveBeenCalledTimes(2);
      });
    });
  });

  it('renders the `FeedbackWidget` component', () => {
    expect(findFeedbackWidget().exists()).toBe(true);
  });

  it('passes the correct props to the `PickUpWidget` component', () => {
    expect(findPickUpWidget().props()).toEqual({
      lastPushEvent,
    });
  });

  it('renders the PickUpWidget component', () => {
    expect(findPickUpWidget().exists()).toBe(true);
  });

  describe('when there is no lastPushEvent', () => {
    it('does not render the PickUpWidget component', () => {
      createWrapper({
        lastPushEvent: null,
      });
      expect(findPickUpWidget().exists()).toBe(false);
    });
  });

  describe('when lastPushEvent.show_widget is false but there is valid push event data', () => {
    it('shows the widget', () => {
      createWrapper({ lastPushEvent: { show_widget: false, branch_name: 'feature_branch' } });

      expect(findPickUpWidget().exists()).toBe(true);
    });
  });
});
