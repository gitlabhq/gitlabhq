import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import workItemsWidgetMetadataQuery from '~/homepage/graphql/queries/work_items_widget_metadata.query.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_ISSUES,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  TRACKING_PROPERTY_AUTHORED_BY_YOU,
} from '~/homepage/tracking_constants';
import { withItems, withoutItems } from './mocks/work_items_widget_metadata_query_mocks';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('WorkItemsWidget', () => {
  Vue.use(VueApollo);

  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_AUTHORED_BY_YOU_PATH = '/authored/to/you/path';
  const MOCK_CURRENT_TIME = new Date('2025-06-29T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  const workItemsWidgetMetadataQuerySuccessHandler = (data) => jest.fn().mockResolvedValue(data);

  let wrapper;

  const findAssignedCard = () => wrapper.findAllComponents(GlLink).at(0);
  const findAuthoredCard = () => wrapper.findAllComponents(GlLink).at(1);
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');
  const findAuthoredCount = () => wrapper.findByTestId('authored-count');
  const findAuthoredLastUpdatedAt = () => wrapper.findByTestId('authored-last-updated-at');

  function createWrapper({
    workItemsWidgetMetadataQueryHandler = workItemsWidgetMetadataQuerySuccessHandler(withItems),
  } = {}) {
    const mockApollo = createMockApollo([
      [workItemsWidgetMetadataQuery, workItemsWidgetMetadataQueryHandler],
    ]);
    wrapper = shallowMountExtended(WorkItemsWidget, {
      apolloProvider: mockApollo,
      propsData: {
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
        authoredByYouPath: MOCK_AUTHORED_BY_YOU_PATH,
      },
      stubs: {
        GlSprintf,
        'visibility-change-detector': true,
      },
    });
  }

  describe('cards', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Issues assigned to you" card', () => {
      const card = findAssignedCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Issues assigned to you');
    });

    it('renders the "Issues authored by you" card', () => {
      const card = findAuthoredCard();

      expect(card.exists()).toBe(true);
      expect(card.text()).toMatch('Issues authored by you');
    });
  });

  describe('metadata', () => {
    it("shows the counts' loading state and no timestamp until the query has resolved", () => {
      createWrapper();

      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);

      expect(findAssignedCount().text()).toBe('-');
      expect(findAuthoredCount().text()).toBe('-');
    });

    it('shows the metadata once the query has resolved', async () => {
      createWrapper();
      await waitForPromises();

      expect(findAssignedCount().text()).toBe('5');
      expect(findAssignedLastUpdatedAt().text()).toBe('1 day ago');
      expect(findAuthoredCount().text()).toBe('32');
      expect(findAuthoredLastUpdatedAt().text()).toBe('4 days ago');
    });

    it('shows partial metadata when the user has no relevant items', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler:
          workItemsWidgetMetadataQuerySuccessHandler(withoutItems),
      });
      await waitForPromises();

      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);

      expect(findAssignedCount().text()).toBe('0');
      expect(findAuthoredCount().text()).toBe('0');
    });

    it('shows error messages in both cards if the query errors out', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();

      expect(findAssignedCard().text()).toContain(
        'The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
      );
      expect(findAuthoredCard().text()).toContain(
        'The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
      );
      expect(Sentry.captureException).toHaveBeenCalled();

      expect(findAssignedCard().text()).not.toMatch('Issues assigned to you');
      expect(findAuthoredCard().text()).not.toMatch('Issues authored by you');
    });

    it('shows error icons in both cards when in error state', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });
      await waitForPromises();
      const allIcons = wrapper.findAllComponents({ name: 'GlIcon' });

      let errorIconCount = 0;
      for (let i = 0; i < allIcons.length; i += 1) {
        const icon = allIcons.at(i);
        if (icon.props('name') === 'error') {
          expect(icon.props('size')).toBe(16);
          expect(icon.classes('gl-text-red-500')).toBe(true);
          errorIconCount += 1;
        }
      }

      expect(errorIconCount).toBe(2);
    });
  });

  describe('refresh functionality', () => {
    it('refreshes on becoming visible again', async () => {
      const reloadSpy = jest.spyOn(WorkItemsWidget.methods, 'reload').mockImplementation(() => {});

      createWrapper();
      await waitForPromises();
      reloadSpy.mockClear();

      wrapper.vm.reload();
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });
  });

  describe('number formatting', () => {
    it('formats large counts using formatNumberWithScale', async () => {
      const mockData = {
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            assigned: {
              count: 15000,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/1',
                  updatedAt: '2025-06-28T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            authored: {
              count: 1500000,
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/2',
                  updatedAt: '2025-06-25T18:13:25Z',
                  __typename: 'WorkItem',
                },
              ],
              __typename: 'WorkItemConnection',
            },
            __typename: 'CurrentUser',
          },
        },
      };

      createWrapper({
        workItemsWidgetMetadataQueryHandler: workItemsWidgetMetadataQuerySuccessHandler(mockData),
      });
      await waitForPromises();

      expect(findAssignedCount().text()).toBe('15K');
      expect(findAuthoredCount().text()).toBe('1.5M');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('tracks click on "Issues assigned to you" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const assignedCard = findAssignedCard();

      assignedCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_ISSUES,
          property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
        },
        undefined,
      );
    });

    it('tracks click on "Issues authored by you" card', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const authoredCard = findAuthoredCard();

      authoredCard.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_ISSUES,
          property: TRACKING_PROPERTY_AUTHORED_BY_YOU,
        },
        undefined,
      );
    });
  });
});
