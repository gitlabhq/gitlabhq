import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import WorkItemHealthStatus from '~/work_items/components/work_item_health_status.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import waitForPromises from 'helpers/wait_for_promises';
import {
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import setWindowLocation from 'helpers/set_window_location_helper';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_ISSUE } from '~/issues/constants';
import { CREATED_DESC, UPDATED_DESC } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, updateHistory, removeParams } from '~/lib/utils/url_utility';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemsListApp from '~/work_items/pages/work_items_list_app.vue';
import { sortOptions, urlSortParams } from '~/work_items/pages/list/constants';
import getWorkItemStateCountsQuery from '~/work_items/graphql/list/get_work_item_state_counts.query.graphql';
import getWorkItemsQuery from '~/work_items/graphql/list/get_work_items.query.graphql';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import {
  STATE_CLOSED,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  WORK_ITEM_TYPE_ENUM_EPIC,
} from '~/work_items/constants';
import { createRouter } from '~/work_items/router';
import {
  groupWorkItemsQueryResponse,
  groupWorkItemStateCountsQueryResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility');

const skipReason = new SkipReason({
  name: 'WorkItemsListApp component',
  reason: 'Caught error after test environment was torn down',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478775',
});

describeSkipVue3(skipReason, () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const defaultQueryHandler = jest.fn().mockResolvedValue(groupWorkItemsQueryResponse);
  const countsQueryHandler = jest.fn().mockResolvedValue(groupWorkItemStateCountsQueryResponse);
  const mutationHandler = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findWorkItemHealthStatus = () => wrapper.findComponent(WorkItemHealthStatus);
  const findDrawer = () => wrapper.findComponent(WorkItemDrawer);

  const mountComponent = ({
    provide = {},
    queryHandler = defaultQueryHandler,
    sortPreferenceMutationResponse = mutationHandler,
    workItemsViewPreference = false,
    workItemsToggleEnabled = true,
    props = {},
  } = {}) => {
    window.gon = {
      ...window.gon,
      features: {
        workItemsViewPreference,
      },
      current_user_use_work_items_view: workItemsToggleEnabled,
    };
    wrapper = shallowMount(WorkItemsListApp, {
      router: createRouter({ fullPath: '/work_item' }),
      apolloProvider: createMockApollo([
        [getWorkItemsQuery, queryHandler],
        [getWorkItemStateCountsQuery, countsQueryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationResponse],
      ]),
      provide: {
        autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
        fullPath: 'full/path',
        hasEpicsFeature: false,
        hasOkrsFeature: false,
        hasQualityManagementFeature: false,
        initialSort: CREATED_DESC,
        isGroup: true,
        isSignedIn: true,
        workItemType: null,
        ...provide,
      },
      propsData: {
        ...props,
      },
    });
  };

  it('renders loading icon when initially fetching work items', () => {
    mountComponent();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when work items are fetched', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('renders IssuableList component', () => {
      expect(findIssuableList().props()).toMatchObject({
        currentTab: STATUS_OPEN,
        error: '',
        initialSortBy: CREATED_DESC,
        namespace: 'work-items',
        recentSearchesStorageKey: 'issues',
        showWorkItemTypeIcon: true,
        sortOptions,
        tabs: WorkItemsListApp.issuableListTabs,
      });
    });

    it('renders tab counts', () => {
      expect(findIssuableList().props('tabCounts')).toEqual({
        all: 3,
        closed: 1,
        opened: 2,
      });
    });

    it('renders IssueCardStatistics component', () => {
      expect(findIssueCardStatistics().exists()).toBe(true);
    });

    it('renders IssueCardTimeInfo component', () => {
      expect(findIssueCardTimeInfo().exists()).toBe(true);
      expect(findIssueCardTimeInfo().props('isWorkItemList')).toBe(true);
    });

    it('renders IssueHealthStatus component', () => {
      expect(findWorkItemHealthStatus().exists()).toBe(true);
    });

    it('renders work items', () => {
      expect(findIssuableList().props('issuables')).toEqual(
        groupWorkItemsQueryResponse.data.group.workItems.nodes,
      );
    });

    it('calls query to fetch work items', () => {
      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full/path',
          includeDescendants: true,
          sort: CREATED_DESC,
          state: STATUS_OPEN,
          firstPageSize: 20,
          types: ['ISSUE', 'INCIDENT', 'TASK'],
        }),
      );

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeProjects: false,
        }),
      );
    });

    it('calls `getParameterByName` to get the `show` param', () => {
      expect(getParameterByName).toHaveBeenCalledWith(DETAIL_VIEW_QUERY_PARAM_NAME);
    });
  });

  describe('pagination controls', () => {
    describe.each`
      description                                                | pageInfo                                          | exists
      ${'when hasNextPage=true and hasPreviousPage=true'}        | ${{ hasNextPage: true, hasPreviousPage: true }}   | ${true}
      ${'when hasNextPage=true'}                                 | ${{ hasNextPage: true, hasPreviousPage: false }}  | ${true}
      ${'when hasPreviousPage=true'}                             | ${{ hasNextPage: false, hasPreviousPage: true }}  | ${true}
      ${'when neither hasNextPage nor hasPreviousPage are true'} | ${{ hasNextPage: false, hasPreviousPage: false }} | ${false}
    `('$description', ({ pageInfo, exists }) => {
      it(`${exists ? 'renders' : 'does not render'} pagination controls`, async () => {
        const response = cloneDeep(groupWorkItemsQueryResponse);
        Object.assign(response.data.group.workItems.pageInfo, pageInfo);
        mountComponent({ queryHandler: jest.fn().mockResolvedValue(response) });
        await waitForPromises();

        expect(findIssuableList().props('showPaginationControls')).toBe(exists);
      });
    });
  });

  describe('when workItemType is provided', () => {
    it('filters work items by workItemType', async () => {
      const type = 'EPIC';
      mountComponent({ provide: { workItemType: type } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full/path',
          includeDescendants: true,
          sort: CREATED_DESC,
          state: STATUS_OPEN,
          types: type,
        }),
      );
    });
  });

  describe('when workItemType EPIC is provided', () => {
    it('sends excludeProjects variable in GraphQL query', async () => {
      const type = 'EPIC';
      mountComponent({ provide: { workItemType: type } });

      await waitForPromises();

      expect(defaultQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          excludeProjects: true,
        }),
      );
    });
  });

  describe('when there is an error fetching work items', () => {
    const message = 'Something went wrong when fetching work items. Please try again.';

    beforeEach(async () => {
      mountComponent({ queryHandler: jest.fn().mockRejectedValue(new Error('ERROR')) });
      await waitForPromises();
    });

    it('renders an error message', () => {
      expect(findIssuableList().props('error')).toBe(message);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(wrapper.text()).not.toContain(message);
    });
  });

  describe('watcher', () => {
    describe('when eeCreatedWorkItemsCount is updated', () => {
      it('refetches work items', async () => {
        mountComponent();
        await waitForPromises();

        expect(defaultQueryHandler).toHaveBeenCalledTimes(1);

        await wrapper.setProps({ eeWorkItemUpdateCount: 1 });

        expect(defaultQueryHandler).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };
    const preloadedUsers = [
      { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
    ];

    beforeEach(() => {
      window.gon = {
        current_user_id: mockCurrentUser.id,
        current_user_fullname: mockCurrentUser.name,
        current_username: mockCurrentUser.username,
        current_user_avatar_url: mockCurrentUser.avatar_url,
      };
    });

    it('renders all tokens', async () => {
      mountComponent();
      await waitForPromises();

      expect(findIssuableList().props('searchTokens')).toMatchObject([
        { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers },
        { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
        { type: TOKEN_TYPE_CONFIDENTIAL },
        { type: TOKEN_TYPE_GROUP },
        { type: TOKEN_TYPE_LABEL },
        { type: TOKEN_TYPE_MILESTONE },
        { type: TOKEN_TYPE_MY_REACTION },
        { type: TOKEN_TYPE_SEARCH_WITHIN },
        { type: TOKEN_TYPE_TYPE },
      ]);
    });

    describe('when workItemType is defined', () => {
      it('renders all tokens except "Type"', async () => {
        mountComponent({ provide: { workItemType: 'EPIC' } });
        await waitForPromises();

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_GROUP },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_SEARCH_WITHIN },
        ]);
      });
    });
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(async () => {
        getParameterByName.mockImplementation((args) =>
          jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
        );
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      it('fetches filtered work items', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', [
          { type: FILTERED_SEARCH_TERM, value: { data: 'find issues', operator: 'undefined' } },
          { type: TOKEN_TYPE_AUTHOR, value: { data: 'homer', operator: OPERATOR_IS } },
          { type: TOKEN_TYPE_SEARCH_WITHIN, value: { data: 'TITLE', operator: OPERATOR_IS } },
        ]);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            search: 'find issues',
            authorUsername: 'homer',
            in: 'TITLE',
          }),
        );
      });
    });

    describe.each`
      event              | params
      ${'next-page'}     | ${{ afterCursor: 'endCursor', firstPageSize: 20 }}
      ${'previous-page'} | ${{ beforeCursor: 'startCursor', lastPageSize: 20 }}
    `('when "$event" event is emitted by IssuableList', ({ event, params }) => {
      beforeEach(async () => {
        getParameterByName.mockImplementation((args) =>
          jest.requireActual('~/lib/utils/url_utility').getParameterByName(args),
        );
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit(event);
      });

      it('scrolls to the top', () => {
        expect(scrollUp).toHaveBeenCalled();
      });

      it('fetches next/previous work items', () => {
        expect(defaultQueryHandler).toHaveBeenLastCalledWith(expect.objectContaining(params));
      });
    });

    describe('when "page-size-change" event is emitted by IssuableList', () => {
      it('updates list with new page size', async () => {
        mountComponent();
        await waitForPromises();

        findIssuableList().vm.$emit('page-size-change', 50);
        await nextTick();

        expect(defaultQueryHandler).toHaveBeenLastCalledWith(
          expect.objectContaining({ firstPageSize: 50 }),
        );
      });
    });

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
          await waitForPromises();

          findIssuableList().vm.$emit('sort', sortKey);
          await waitForPromises();

          expect(defaultQueryHandler).toHaveBeenCalledWith(
            expect.objectContaining({ sort: sortKey }),
          );
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', async () => {
          mountComponent();
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationHandler).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', async () => {
          mountComponent({ provide: { isSignedIn: false } });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationHandler).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('work item drawer', () => {
    describe('when rendering issues list', () => {
      describe('when issues_list_drawer feature is disabled', () => {
        it('is not rendered when feature is disabled', async () => {
          mountComponent({
            workItemsToggleEnabled: false,
            provide: {
              glFeatures: {
                issuesListDrawer: false,
                epicsListDrawer: true,
              },
            },
          });
          await waitForPromises();

          expect(findDrawer().exists()).toBe(false);
        });
      });

      describe('when issues_list_drawer feature is enabled', () => {
        beforeEach(async () => {
          mountComponent({
            provide: {
              glFeatures: {
                issuesListDrawer: true,
                epicsListDrawer: false,
              },
            },
          });
          await waitForPromises();
        });

        it('is rendered when feature is enabled', () => {
          expect(findDrawer().exists()).toBe(true);
        });

        describe('selecting issues', () => {
          const issue = groupWorkItemsQueryResponse.data.group.workItems.nodes[0];
          const payload = {
            iid: issue.iid,
            webUrl: issue.webUrl,
            fullPath: issue.namespace.fullPath,
          };

          beforeEach(async () => {
            findIssuableList().vm.$emit('select-issuable', payload);

            await nextTick();
          });

          it('opens drawer when work item is selected', () => {
            expect(findDrawer().props('open')).toBe(true);
            expect(findDrawer().props('activeItem')).toEqual(payload);
          });

          const checkThatDrawerPropsAreEmpty = () => {
            expect(findDrawer().props('activeItem')).toBeNull();
            expect(findDrawer().props('open')).toBe(false);
          };

          it('resets the selected item when the drawer is closed', async () => {
            findDrawer().vm.$emit('close');

            await nextTick();

            checkThatDrawerPropsAreEmpty();
          });

          it('refetches and resets when work item is deleted', async () => {
            expect(defaultQueryHandler).toHaveBeenCalledTimes(1);

            findDrawer().vm.$emit('workItemDeleted');

            await nextTick();

            checkThatDrawerPropsAreEmpty();

            expect(defaultQueryHandler).toHaveBeenCalledTimes(2);
          });

          it('refetches when the selected work item is closed', async () => {
            expect(defaultQueryHandler).toHaveBeenCalledTimes(1);

            // component displays open work items by default
            findDrawer().vm.$emit('work-item-updated', {
              state: STATE_CLOSED,
            });

            await nextTick();

            expect(defaultQueryHandler).toHaveBeenCalledTimes(2);
          });
        });
      });
    });

    describe('when rendering epics list', () => {
      describe('when epics_list_drawer feature is disabled', () => {
        it('is not rendered when feature is disabled', async () => {
          mountComponent({
            workItemsToggleEnabled: false,
            provide: {
              glFeatures: {
                issuesListDrawer: true,
                epicsListDrawer: false,
              },
              workItemType: WORK_ITEM_TYPE_ENUM_EPIC,
            },
          });
          await waitForPromises();

          expect(findDrawer().exists()).toBe(false);
        });
      });

      describe('when issues_list_drawer feature is enabled', () => {
        beforeEach(async () => {
          mountComponent({
            provide: {
              glFeatures: {
                issuesListDrawer: false,
                epicsListDrawer: true,
              },
              workItemType: WORK_ITEM_TYPE_ENUM_EPIC,
            },
          });
          await waitForPromises();
        });

        it('is rendered when feature is enabled', () => {
          expect(findDrawer().exists()).toBe(true);
        });
      });
    });

    describe('When the `show` parameter matches an item in the list', () => {
      it('displays the item in the drawer', async () => {
        const issue = groupWorkItemsQueryResponse.data.group.workItems.nodes[0];
        const showParams = {
          id: getIdFromGraphQLId(issue.id),
          iid: issue.iid,
          full_path: issue.namespace.fullPath,
        };
        const show = btoa(JSON.stringify(showParams));
        setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
        getParameterByName.mockReturnValue(show);
        mountComponent({
          provide: {
            workItemType: TYPE_ISSUE,
            glFeatures: {
              issuesListDrawer: true,
            },
          },
        });
        await waitForPromises();
        await nextTick();
        expect(findDrawer().props('open')).toBe(true);
        expect(findDrawer().props('activeItem')).toMatchObject(issue);
      });
    });

    describe('When the `show` parameter does not match an item in the list', () => {
      beforeEach(async () => {
        const showParams = { id: 9999, iid: '9999', full_path: 'does/not/match' };
        const show = btoa(JSON.stringify(showParams));
        setWindowLocation(`?${DETAIL_VIEW_QUERY_PARAM_NAME}=${show}`);
        getParameterByName.mockReturnValue(show);
        mountComponent({
          provide: {
            workItemType: TYPE_ISSUE,
            glFeatures: {
              issuesListDrawer: true,
            },
          },
        });
        await waitForPromises();
      });
      it('calls `updateHistory', () => {
        expect(updateHistory).toHaveBeenCalled();
      });
      it('calls `removeParams` to remove the `show` param', () => {
        expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
      });
    });
  });

  describe('when withTabs is false', () => {
    beforeEach(async () => {
      mountComponent({ props: { withTabs: false } });
      await waitForPromises();
    });
    it('includes "State", in searchTokens', () => {
      expect(
        findIssuableList()
          .props('searchTokens')
          .map((token) => token.type),
      ).toContain(TOKEN_TYPE_STATE);
    });
    it('passes empty array in the tabs props', () => {
      expect(findIssuableList().props('tabs')).toEqual([]);
    });
  });
});
