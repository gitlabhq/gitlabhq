import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import VueRouter from 'vue-router';
import AxiosMockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { joinPaths } from '~/lib/utils/url_utility';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollUp } from '~/lib/utils/scroll_utils';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getSortKey, getSortOptions } from '~/issues/list/utils';
import { STATUS_CLOSED, STATUS_OPEN, STATUS_ALL } from '~/issues/service_desk/constants';
import getServiceDeskIssuesQuery from 'ee_else_ce/issues/service_desk/queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCountsQuery from 'ee_else_ce/issues/service_desk/queries/get_service_desk_issues_counts.query.graphql';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import setSortingPreferenceMutation from '~/issues/service_desk/queries/set_sorting_preference.mutation.graphql';
import ServiceDeskListApp from '~/issues/service_desk/components/service_desk_list_app.vue';
import InfoBanner from '~/issues/service_desk/components/info_banner.vue';
import EmptyStateWithAnyIssues from '~/issues/service_desk/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '~/issues/service_desk/components/empty_state_without_any_issues.vue';
import { createAlert, VARIANT_INFO } from '~/alert';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  CREATED_DESC,
  UPDATED_DESC,
  RELATIVE_POSITION_ASC,
  RELATIVE_POSITION,
  urlSortParams,
} from '~/issues/list/constants';
import {
  getServiceDeskIssuesQueryResponse,
  getServiceDeskIssuesQueryEmptyResponse,
  getServiceDeskIssuesCountsQueryResponse,
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
  filteredTokens,
  urlParams,
  locationSearch,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/alert');
jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));

describe('CE ServiceDeskListApp', () => {
  let wrapper;
  let router;
  let axiosMock;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const defaultProvide = {
    releasesPath: 'releases/path',
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
    hasBlockedIssuesFeature: false,
    hasIterationsFeature: true,
    hasIssueWeightsFeature: true,
    hasIssuableHealthStatusFeature: true,
    groupPath: 'group/path',
    emptyStateSvgPath: 'empty-state.svg',
    isProject: true,
    isSignedIn: true,
    fullPath: 'path/to/project',
    isServiceDeskSupported: true,
    hasAnyIssues: true,
    initialSort: CREATED_DESC,
    isIssueRepositioningDisabled: false,
    issuablesLoading: false,
    showPaginationControls: true,
    useKeysetPagination: true,
    hasPreviousPage: getServiceDeskIssuesQueryResponse.data.project.issues.pageInfo.hasPreviousPage,
    hasNextPage: getServiceDeskIssuesQueryResponse.data.project.issues.pageInfo.hasNextPage,
  };

  let defaultQueryResponse = getServiceDeskIssuesQueryResponse;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(getServiceDeskIssuesQueryResponse);
    defaultQueryResponse.data.project.issues.nodes[0].healthStatus = null;
    defaultQueryResponse.data.project.issues.nodes[0].weight = 5;
  }

  const mockServiceDeskIssuesQueryResponseHandler = jest
    .fn()
    .mockResolvedValue(defaultQueryResponse);
  const mockServiceDeskIssuesQueryEmptyResponseHandler = jest
    .fn()
    .mockResolvedValue(getServiceDeskIssuesQueryEmptyResponse);
  const mockServiceDeskIssuesCountsQueryResponseHandler = jest
    .fn()
    .mockResolvedValue(getServiceDeskIssuesCountsQueryResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findInfoBanner = () => wrapper.findComponent(InfoBanner);
  const findLabelsToken = () =>
    findIssuableList()
      .props('searchTokens')
      .find((token) => token.type === TOKEN_TYPE_LABEL);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);

  const createComponent = ({
    provide = {},
    serviceDeskIssuesQueryResponseHandler = mockServiceDeskIssuesQueryResponseHandler,
    serviceDeskIssuesCountsQueryResponseHandler = mockServiceDeskIssuesCountsQueryResponseHandler,
    sortPreferenceMutationResponse = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
  } = {}) => {
    const requestHandlers = [
      [getServiceDeskIssuesQuery, serviceDeskIssuesQueryResponseHandler],
      [getServiceDeskIssuesCountsQuery, serviceDeskIssuesCountsQueryResponseHandler],
      [setSortingPreferenceMutation, sortPreferenceMutationResponse],
    ];

    router = new VueRouter({ mode: 'history' });

    return shallowMount(ServiceDeskListApp, {
      apolloProvider: createMockApollo(
        requestHandlers,
        {},
        {
          typePolicies: {
            Query: {
              fields: {
                project: {
                  merge: true,
                },
              },
            },
          },
        },
      ),
      router,
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(TEST_HOST);
    axiosMock = new AxiosMockAdapter(axios);
    wrapper = createComponent();
    return waitForPromises();
  });

  afterEach(() => {
    axiosMock.reset();
  });

  it('renders the issuable list with skeletons while fetching service desk issues', async () => {
    wrapper = createComponent();
    await nextTick();

    expect(findIssuableList().props('issuablesLoading')).toBe(true);

    await waitForPromises();

    expect(findIssuableList().props('issuablesLoading')).toBe(false);
  });

  it('fetches service desk issues and renders them in the issuable list', () => {
    expect(findIssuableList().props()).toMatchObject({
      namespace: 'service-desk',
      recentSearchesStorageKey: 'service-desk-issues',
      issuables: defaultQueryResponse.data.project.issues.nodes,
      tabs: issuableListTabs,
      currentTab: STATUS_OPEN,
      tabCounts: {
        opened: 1,
        closed: 1,
        all: 1,
      },
      sortOptions: getSortOptions({
        hasBlockedIssuesFeature: defaultProvide.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: defaultProvide.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: defaultProvide.hasIssueWeightsFeature,
      }),
      initialSortBy: CREATED_DESC,
      isManualOrdering: false,
    });
  });

  describe('InfoBanner', () => {
    it('renders when Service Desk is supported and has any number of issues', () => {
      expect(findInfoBanner().exists()).toBe(true);
    });

    it('does not render when Service Desk is not supported and has any number of issues', () => {
      wrapper = createComponent({ provide: { isServiceDeskSupported: false } });

      expect(findInfoBanner().exists()).toBe(false);
    });

    it('does not render, when there are no issues', () => {
      wrapper = createComponent({
        serviceDeskIssuesQueryResponseHandler: mockServiceDeskIssuesQueryEmptyResponseHandler,
      });

      expect(findInfoBanner().exists()).toBe(false);
    });
  });

  describe('slots provided to issue list', () => {
    describe('Empty states', () => {
      describe('when there are issues', () => {
        it('shows EmptyStateWithAnyIssues component', () => {
          setWindowLocation(locationSearch);
          wrapper = createComponent({
            serviceDeskIssuesQueryResponseHandler: mockServiceDeskIssuesQueryEmptyResponseHandler,
          });

          expect(wrapper.findComponent(EmptyStateWithAnyIssues).props()).toEqual({
            hasSearch: true,
            isOpenTab: true,
          });
        });
      });

      describe('when there are no issues', () => {
        it('shows EmptyStateWithoutAnyIssues component', () => {
          wrapper = createComponent({
            provide: { hasAnyIssues: false },
            serviceDeskIssuesQueryResponseHandler: mockServiceDeskIssuesQueryEmptyResponseHandler,
          });

          expect(wrapper.findComponent(EmptyStateWithoutAnyIssues).exists()).toBe(true);
        });
      });
    });

    it('includes IssueCardTimeInfo component', async () => {
      wrapper = createComponent();
      await nextTick();

      expect(findIssueCardTimeInfo().exists()).toBe(true);
    });

    it('includes IssueCardStatistics component', async () => {
      wrapper = createComponent();
      await nextTick();

      expect(findIssueCardStatistics().exists()).toBe(true);
    });
  });

  describe('Initial url params', () => {
    describe('search', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);
        wrapper = createComponent();

        expect(router.history.current.query).toMatchObject({ search: 'find issues' });
      });
    });

    describe('sort', () => {
      describe('when initial sort value uses old enum values', () => {
        const oldEnumSortValues = Object.values(urlSortParams);

        it.each(oldEnumSortValues)('initial sort is set with value %s', async (sort) => {
          wrapper = createComponent({ provide: { initialSort: sort } });
          await waitForPromises();

          expect(findIssuableList().props('initialSortBy')).toBe(getSortKey(sort));
        });
      });

      describe('when initial sort value uses new GraphQL enum values', () => {
        const graphQLEnumSortValues = Object.keys(urlSortParams);

        it.each(graphQLEnumSortValues)('initial sort is set with value %s', async (sort) => {
          wrapper = createComponent({ provide: { initialSort: sort.toLowerCase() } });
          await waitForPromises();

          expect(findIssuableList().props('initialSortBy')).toBe(sort);
        });
      });

      describe('when initial sort value is invalid', () => {
        it.each(['', 'asdf', null, undefined])(
          'initial sort is set to value CREATED_DESC',
          async (sort) => {
            wrapper = createComponent({ provide: { initialSort: sort } });
            await waitForPromises();

            expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
          },
        );
      });

      describe('when sort is manual and issue repositioning is disabled', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            provide: { initialSort: RELATIVE_POSITION, isIssueRepositioningDisabled: true },
          });
          await waitForPromises();
        });

        it('changes the sort to the default of created descending', () => {
          expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: ServiceDeskListApp.i18n.issueRepositioningMessage,
            variant: VARIANT_INFO,
          });
        });
      });
    });

    describe('state', () => {
      it('is set from the url params', async () => {
        const initialState = STATUS_ALL;
        setWindowLocation(`?state=${initialState}`);
        wrapper = createComponent();
        await waitForPromises();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
    });

    describe('filter tokens', () => {
      it('are set from the url params', () => {
        setWindowLocation(locationSearch);
        wrapper = createComponent();

        expect(findIssuableList().props('initialFilterValue')).toEqual(filteredTokens);
      });
    });
  });

  describe('Tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    describe('when user is signed out', () => {
      beforeEach(() => {
        wrapper = createComponent({ provide: { isSignedIn: false } });
        return waitForPromises();
      });

      it('does not render My-Reaction or Confidential tokens', () => {
        expect(findIssuableList().props('searchTokens')).not.toMatchObject([
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers: [mockCurrentUser] },
          { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers: [mockCurrentUser] },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_CONFIDENTIAL },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      beforeEach(() => {
        window.gon = {
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        wrapper = createComponent();
        return waitForPromises();
      });

      it('renders all tokens alphabetically', () => {
        const preloadedUsers = [
          { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers },
          { type: TOKEN_TYPE_CONFIDENTIAL },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_MY_REACTION },
          { type: TOKEN_TYPE_RELEASE },
          { type: TOKEN_TYPE_SEARCH_WITHIN },
        ]);
      });
    });
  });

  describe('Events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(async () => {
        wrapper = createComponent();
        router.push = jest.fn();
        await waitForPromises();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });

      it('updates url to the new tab', () => {
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({ state: STATUS_CLOSED }),
        });
      });
    });

    describe('when "reorder" event is emitted by IssuableList', () => {
      const issueOne = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/1',
        iid: '101',
        reference: 'group/project#1',
        webPath: '/group/project/-/issues/1',
      };
      const issueTwo = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/2',
        iid: '102',
        reference: 'group/project#2',
        webPath: '/group/project/-/issues/2',
      };
      const issueThree = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/3',
        iid: '103',
        reference: 'group/project#3',
        webPath: '/group/project/-/issues/3',
      };
      const issueFour = {
        ...defaultQueryResponse.data.project.issues.nodes[0],
        id: 'gid://gitlab/Issue/4',
        iid: '104',
        reference: 'group/project#4',
        webPath: '/group/project/-/issues/4',
      };
      const response = () => ({
        data: {
          project: {
            id: '1',
            issues: {
              ...defaultQueryResponse.data.project.issues,
              nodes: [issueOne, issueTwo, issueThree, issueFour],
            },
          },
        },
      });

      describe('when successful', () => {
        describe.each`
          description                       | issueToMove   | oldIndex | newIndex | moveBeforeId    | moveAfterId
          ${'to the beginning of the list'} | ${issueThree} | ${2}     | ${0}     | ${null}         | ${issueOne.id}
          ${'down the list'}                | ${issueOne}   | ${0}     | ${1}     | ${issueTwo.id}  | ${issueThree.id}
          ${'up the list'}                  | ${issueThree} | ${2}     | ${1}     | ${issueOne.id}  | ${issueTwo.id}
          ${'to the end of the list'}       | ${issueTwo}   | ${1}     | ${3}     | ${issueFour.id} | ${null}
        `(
          'when moving issue $description',
          ({ issueToMove, oldIndex, newIndex, moveBeforeId, moveAfterId }) => {
            beforeEach(() => {
              wrapper = createComponent({
                serviceDeskIssuesQueryResponseHandler: jest.fn().mockResolvedValue(response()),
              });
              return waitForPromises();
            });

            it('makes API call to reorder the issue', async () => {
              findIssuableList().vm.$emit('reorder', { oldIndex, newIndex });
              await waitForPromises();

              expect(axiosMock.history.put[0]).toMatchObject({
                url: joinPaths(issueToMove.webPath, 'reorder'),
                data: JSON.stringify({
                  move_before_id: getIdFromGraphQLId(moveBeforeId),
                  move_after_id: getIdFromGraphQLId(moveAfterId),
                }),
              });
            });
          },
        );
      });

      describe('when unsuccessful', () => {
        beforeEach(() => {
          wrapper = createComponent({
            serviceDeskIssuesQueryResponseHandler: jest.fn().mockResolvedValue(response()),
          });
          return waitForPromises();
        });

        it('displays an error message', async () => {
          axiosMock
            .onPut(joinPaths(issueOne.webPath, 'reorder'))
            .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

          findIssuableList().vm.$emit('reorder', { oldIndex: 0, newIndex: 1 });
          await waitForPromises();

          expect(findIssuableList().props('error')).toBe(ServiceDeskListApp.i18n.reorderError);
          expect(Sentry.captureException).toHaveBeenCalledWith(
            new Error('Request failed with status code 500'),
          );
        });
      });
    });

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we can trigger an update when emitting a sort key
          wrapper =
            sortKey === CREATED_DESC
              ? createComponent({ provide: { initialSort: UPDATED_DESC } })
              : createComponent();
          router.push = jest.fn();
          await waitForPromises();

          findIssuableList().vm.$emit('sort', sortKey);

          expect(router.push).toHaveBeenCalledWith({
            query: expect.objectContaining({ sort: urlSortParams[sortKey] }),
          });
        },
      );

      describe('when issue repositioning is disabled', () => {
        const initialSort = CREATED_DESC;

        beforeEach(async () => {
          wrapper = createComponent({
            provide: { initialSort, isIssueRepositioningDisabled: true },
          });
          router.push = jest.fn();
          await waitForPromises();

          findIssuableList().vm.$emit('sort', RELATIVE_POSITION_ASC);
        });

        it('does not update the sort to manual', () => {
          expect(router.push).not.toHaveBeenCalled();
        });

        it('shows an alert to tell the user that manual reordering is disabled', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: ServiceDeskListApp.i18n.issueRepositioningMessage,
            variant: VARIANT_INFO,
          });
        });
      });

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', async () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          wrapper = createComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          wrapper = createComponent({ sortPreferenceMutationResponse: mutationMock });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', async () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          wrapper = createComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationResponse: mutationMock,
          });
          await waitForPromises();

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });

    describe.each`
      event              | params
      ${'next-page'}     | ${{ page_after: 'endcursor', page_before: undefined, first_page_size: 20, last_page_size: undefined }}
      ${'previous-page'} | ${{ page_after: undefined, page_before: 'startcursor', first_page_size: undefined, last_page_size: 20 }}
    `('when "$event" event is emitted by IssuableList', ({ event, params }) => {
      beforeEach(async () => {
        wrapper = createComponent({
          data: {
            pageInfo: {
              endCursor: 'endCursor',
              startCursor: 'startCursor',
            },
          },
        });
        await waitForPromises();
        router.push = jest.fn();

        findIssuableList().vm.$emit(event);
      });

      it('scrolls to the top', () => {
        expect(scrollUp).toHaveBeenCalled();
      });

      it('updates url', () => {
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining(params),
        });
      });
    });

    describe('when "filter" event is emitted by IssuableList', () => {
      it('updates IssuableList with url params', async () => {
        wrapper = createComponent();
        router.push = jest.fn();
        await waitForPromises();

        findIssuableList().vm.$emit('filter', filteredTokens);
        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining(urlParams),
        });
      });
    });

    describe('when "page-size-change" event is emitted by IssuableList', () => {
      it('updates url params with new page size', async () => {
        wrapper = createComponent();
        router.push = jest.fn();
        await waitForPromises();

        findIssuableList().vm.$emit('page-size-change', 50);
        await nextTick();

        expect(router.push).toHaveBeenCalledTimes(1);
        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({ first_page_size: 50 }),
        });
      });
    });
  });

  describe('Errors', () => {
    describe.each`
      error                      | responseHandler                                  | message
      ${'fetching issues'}       | ${'serviceDeskIssuesQueryResponseHandler'}       | ${'An error occurred while loading issues'}
      ${'fetching issue counts'} | ${'serviceDeskIssuesCountsQueryResponseHandler'} | ${'An error occurred while getting issue counts'}
    `('when there is an error $error', ({ responseHandler, message }) => {
      beforeEach(() => {
        wrapper = createComponent({
          [responseHandler]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
      });

      it('is captured with Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      wrapper = createComponent({
        serviceDeskIssuesQueryResponseHandler: jest.fn().mockRejectedValue(new Error()),
      });
      await waitForPromises();
      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(findIssuableList().props('error')).toBe('');
    });
  });

  describe('When providing token for labels', () => {
    it('passes function to fetchLatestLabels property if frontend caching is enabled', async () => {
      wrapper = createComponent({
        provide: {
          glFeatures: {
            frontendCaching: true,
          },
        },
      });
      await waitForPromises();

      expect(typeof findLabelsToken().fetchLatestLabels).toBe('function');
    });

    it('passes null to fetchLatestLabels property if frontend caching is disabled', async () => {
      wrapper = createComponent({
        provide: {
          glFeatures: {
            frontendCaching: false,
          },
        },
      });
      await waitForPromises();

      expect(findLabelsToken().fetchLatestLabels).toBe(null);
    });
  });
});
