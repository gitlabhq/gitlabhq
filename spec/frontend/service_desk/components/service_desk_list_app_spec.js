import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import VueRouter from 'vue-router';
import * as Sentry from '@sentry/browser';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, STATUS_OPEN, STATUS_ALL } from '~/service_desk/constants';
import getServiceDeskIssuesQuery from 'ee_else_ce/service_desk/queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCountsQuery from 'ee_else_ce/service_desk/queries/get_service_desk_issues_counts.query.graphql';
import ServiceDeskListApp from '~/service_desk/components/service_desk_list_app.vue';
import InfoBanner from '~/service_desk/components/info_banner.vue';
import EmptyStateWithAnyIssues from '~/service_desk/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '~/service_desk/components/empty_state_without_any_issues.vue';

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
  getServiceDeskIssuesQueryResponse,
  getServiceDeskIssuesQueryEmptyResponse,
  getServiceDeskIssuesCountsQueryResponse,
  filteredTokens,
  urlParams,
  locationSearch,
} from '../mock_data';

jest.mock('@sentry/browser');

describe('CE ServiceDeskListApp', () => {
  let wrapper;
  let router;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const defaultProvide = {
    releasesPath: 'releases/path',
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
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
    initialSort: '',
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

  const createComponent = ({
    provide = {},
    serviceDeskIssuesQueryResponseHandler = mockServiceDeskIssuesQueryResponseHandler,
    serviceDeskIssuesCountsQueryResponseHandler = mockServiceDeskIssuesCountsQueryResponseHandler,
  } = {}) => {
    const requestHandlers = [
      [getServiceDeskIssuesQuery, serviceDeskIssuesQueryResponseHandler],
      [getServiceDeskIssuesCountsQuery, serviceDeskIssuesCountsQueryResponseHandler],
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
    wrapper = createComponent();
    return waitForPromises();
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

  describe('Initial url params', () => {
    describe('search', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);
        wrapper = createComponent();

        expect(router.history.current.query).toMatchObject({ search: 'find issues' });
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
  });

  describe('Errors', () => {
    describe.each`
      error                      | responseHandler
      ${'fetching issues'}       | ${'serviceDeskIssuesQueryResponseHandler'}
      ${'fetching issue counts'} | ${'serviceDeskIssuesCountsQueryResponseHandler'}
    `('when there is an error $error', ({ responseHandler }) => {
      beforeEach(() => {
        wrapper = createComponent({
          [responseHandler]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
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
