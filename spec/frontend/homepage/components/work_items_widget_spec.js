import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';
import workItemsWidgetMetadataQuery from '~/homepage/graphql/queries/work_items_widget_metadata.query.graphql';
import { withItems, withoutItems } from './mocks/work_items_widget_metadata_query_mocks';

describe('WorkItemsWidget', () => {
  Vue.use(VueApollo);

  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';
  const MOCK_AUTHORED_BY_YOU_PATH = '/authored/to/you/path';
  const MOCK_CURRENT_TIME = new Date('2025-06-29T18:13:25Z');

  useFakeDate(MOCK_CURRENT_TIME);

  const workItemsWidgetMetadataQueryHandler = (data) => jest.fn().mockResolvedValue(data);

  let wrapper;

  const findGlLinks = () => wrapper.findAllComponents(GlLink);
  const findAssignedCount = () => wrapper.findByTestId('assigned-count');
  const findAssignedLastUpdatedAt = () => wrapper.findByTestId('assigned-last-updated-at');
  const findAuthoredCount = () => wrapper.findByTestId('authored-count');
  const findAuthoredLastUpdatedAt = () => wrapper.findByTestId('authored-last-updated-at');

  function createWrapper({ workItemsWidgetMetadataQueryMock = withItems } = {}) {
    const mockApollo = createMockApollo([
      [
        workItemsWidgetMetadataQuery,
        workItemsWidgetMetadataQueryHandler(workItemsWidgetMetadataQueryMock),
      ],
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
      expect(link.text()).toBe('Assigned to you');
    });

    it('renders the "Authored by you" link', () => {
      const link = findGlLinks().at(1);

      expect(link.props('href')).toBe(MOCK_AUTHORED_BY_YOU_PATH);
      expect(link.text()).toBe('Authored by you');
    });
  });

  describe('metadata', () => {
    it('does not show any metadata until the query has resolved', () => {
      createWrapper();

      expect(findAssignedCount().exists()).toBe(false);
      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredCount().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);
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
      createWrapper({ workItemsWidgetMetadataQueryMock: withoutItems });
      await waitForPromises();

      expect(findAssignedLastUpdatedAt().exists()).toBe(false);
      expect(findAuthoredLastUpdatedAt().exists()).toBe(false);

      expect(findAssignedCount().text()).toBe('0');
      expect(findAuthoredCount().text()).toBe('0');
    });
  });
});
