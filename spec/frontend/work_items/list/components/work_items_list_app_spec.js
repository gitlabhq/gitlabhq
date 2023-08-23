import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { STATUS_OPEN } from '~/issues/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';
import getWorkItemsQuery from '~/work_items/list/queries/get_work_items.query.graphql';
import { groupWorkItemsQueryResponse } from '../../mock_data';

jest.mock('@sentry/browser');

describe('WorkItemsListApp component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultQueryHandler = jest.fn().mockResolvedValue(groupWorkItemsQueryResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);

  const mountComponent = ({ queryHandler = defaultQueryHandler } = {}) => {
    wrapper = shallowMount(WorkItemsListApp, {
      apolloProvider: createMockApollo([[getWorkItemsQuery, queryHandler]]),
      provide: {
        fullPath: 'full/path',
      },
    });
  };

  it('renders IssuableList component', () => {
    mountComponent();

    expect(findIssuableList().props()).toMatchObject({
      currentTab: STATUS_OPEN,
      error: '',
      issuables: [],
      issuablesLoading: true,
      namespace: 'work-items',
      recentSearchesStorageKey: 'issues',
      searchTokens: [],
      showWorkItemTypeIcon: true,
      sortOptions: [],
      tabs: WorkItemsListApp.issuableListTabs,
    });
  });

  it('renders IssueCardStatistics component', () => {
    mountComponent();

    expect(findIssueCardStatistics().exists()).toBe(true);
  });

  it('renders IssueCardTimeInfo component', () => {
    mountComponent();

    expect(findIssueCardTimeInfo().exists()).toBe(true);
  });

  it('renders work items', async () => {
    mountComponent();
    await waitForPromises();

    expect(findIssuableList().props('issuables')).toEqual(
      groupWorkItemsQueryResponse.data.group.workItems.nodes,
    );
  });

  it('fetches work items', () => {
    mountComponent();

    expect(defaultQueryHandler).toHaveBeenCalledWith({ fullPath: 'full/path' });
  });

  describe('when there is an error fetching work items', () => {
    beforeEach(async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue(new Error('ERROR')) });
      await waitForPromises();
    });

    it('renders an error message', () => {
      const message = 'Something went wrong when fetching work items. Please try again.';

      expect(findIssuableList().props('error')).toBe(message);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(findIssuableList().props('error')).toBe('');
    });
  });
});
