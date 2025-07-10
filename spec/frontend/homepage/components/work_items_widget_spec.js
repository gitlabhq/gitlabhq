import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import workItemsWidgetMetadataQuery from '~/homepage/graphql/queries/work_items_widget_metadata.query.graphql';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';
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

  const findGlLinks = () => wrapper.findAllComponents(GlLink);
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');
  const findAuthoredCount = () => wrapper.findByTestId('authored-count');
  const findAuthoredLastUpdatedAt = () => wrapper.findByTestId('authored-last-updated-at');
  const findDetector = () => wrapper.findComponent(VisibilityChangeDetector);

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
    });
  }

  describe('links', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the "Assigned to you" link', () => {
      const link = findGlLinks().at(0);

      expect(link.props('href')).toBe(MOCK_ASSIGNED_TO_YOU_PATH);
      expect(link.text()).toMatch('Assigned to you');
    });

    it('renders the "Authored by you" link', () => {
      const link = findGlLinks().at(1);

      expect(link.props('href')).toBe(MOCK_AUTHORED_BY_YOU_PATH);
      expect(link.text()).toMatch('Authored by you');
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

    it('emits the `fetch-metadata-error` event if the query errors out', async () => {
      createWrapper({
        workItemsWidgetMetadataQueryHandler: () => jest.fn().mockRejectedValue(),
      });

      expect(wrapper.emitted('fetch-metadata-error')).toBeUndefined();

      await waitForPromises();

      expect(wrapper.emitted('fetch-metadata-error')).toHaveLength(1);
      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);

      expect(findAssignedCount().text()).toBe('-');
      expect(findAuthoredCount().text()).toBe('-');
    });
  });

  describe('refresh functionality', () => {
    it('refreshes on becoming visible again', async () => {
      const reloadSpy = jest.spyOn(WorkItemsWidget.methods, 'reload').mockImplementation(() => {});

      createWrapper();
      await waitForPromises();
      reloadSpy.mockClear();

      findDetector().vm.$emit('visible');
      await waitForPromises();

      expect(reloadSpy).toHaveBeenCalled();
      reloadSpy.mockRestore();
    });
  });
});
