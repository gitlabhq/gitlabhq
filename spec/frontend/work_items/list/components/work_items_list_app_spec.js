import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import { STATUS_OPEN } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';
import { sortOptions, urlSortParams } from '~/work_items/list/constants';
import getWorkItemsQuery from '~/work_items/list/queries/get_work_items.query.graphql';
import { groupWorkItemsQueryResponse } from '../../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('WorkItemsListApp component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultQueryHandler = jest.fn().mockResolvedValue(groupWorkItemsQueryResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);

  const mountComponent = ({
    provide = {},
    queryHandler = defaultQueryHandler,
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
  } = {}) => {
    wrapper = shallowMount(WorkItemsListApp, {
      apolloProvider: createMockApollo([
        [getWorkItemsQuery, queryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationResponse],
      ]),
      provide: {
        fullPath: 'full/path',
        initialSort: CREATED_DESC,
        isSignedIn: true,
        ...provide,
      },
    });
  };

  it('renders IssuableList component', () => {
    mountComponent();

    expect(findIssuableList().props()).toMatchObject({
      currentTab: STATUS_OPEN,
      error: '',
      initialSortBy: CREATED_DESC,
      issuables: [],
      issuablesLoading: true,
      namespace: 'work-items',
      recentSearchesStorageKey: 'issues',
      searchTokens: [],
      showWorkItemTypeIcon: true,
      sortOptions,
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

    expect(defaultQueryHandler).toHaveBeenCalledWith({ fullPath: 'full/path', sort: CREATED_DESC });
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

  describe('events', () => {
    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we trigger an update when emitting a sort key
          if (sortKey === CREATED_DESC) {
            mountComponent({ provide: { initialSort: UPDATED_DESC } });
          } else {
            mountComponent();
          }

          findIssuableList().vm.$emit('sort', sortKey);
          await waitForPromises();

          expect(defaultQueryHandler).toHaveBeenCalledWith({
            fullPath: 'full/path',
            sort: sortKey,
          });
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationResponse: mutationMock,
          });

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });
  });
});
