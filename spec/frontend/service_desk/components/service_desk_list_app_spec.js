import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { STATUS_CLOSED, STATUS_OPEN } from '~/service_desk/constants';
import getServiceDeskIssuesQuery from '~/service_desk/queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCountsQuery from '~/service_desk/queries/get_service_desk_issues_counts.query.graphql';
import ServiceDeskListApp from '~/service_desk/components/service_desk_list_app.vue';
import InfoBanner from '~/service_desk/components/info_banner.vue';
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
  getServiceDeskIssuesCountsQueryResponse,
} from '../mock_data';

jest.mock('@sentry/browser');

describe('ServiceDeskListApp', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultProvide = {
    releasesPath: 'releases/path',
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
    hasIterationsFeature: true,
    groupPath: 'group/path',
    emptyStateSvgPath: 'empty-state.svg',
    isProject: true,
    isSignedIn: true,
    fullPath: 'path/to/project',
    isServiceDeskSupported: true,
    hasAnyIssues: true,
  };

  const defaultQueryResponse = getServiceDeskIssuesQueryResponse;

  const mockServiceDeskIssuesQueryResponseHandler = jest
    .fn()
    .mockResolvedValue(defaultQueryResponse);
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
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
    return waitForPromises();
  });

  it('fetches service desk issues and renders them in the issuable list', () => {
    expect(findIssuableList().props()).toMatchObject({
      namespace: 'service-desk',
      recentSearchesStorageKey: 'issues',
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

    it('does not render when Service Desk is not supported and has any number of issues', async () => {
      wrapper = createComponent({ provide: { isServiceDeskSupported: false } });
      await waitForPromises();

      expect(findInfoBanner().exists()).toBe(false);
    });

    it('does not render, when there are no issues', async () => {
      wrapper = createComponent({ provide: { hasAnyIssues: false } });
      await waitForPromises();

      expect(findInfoBanner().exists()).toBe(false);
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
      it('updates ui to the new tab', async () => {
        createComponent();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);

        await nextTick();
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });
    });
  });

  describe('Errors', () => {
    describe.each`
      error                      | responseHandler                                  | message
      ${'fetching issues'}       | ${'serviceDeskIssuesQueryResponseHandler'}       | ${ServiceDeskListApp.i18n.errorFetchingIssues}
      ${'fetching issue counts'} | ${'serviceDeskIssuesCountsQueryResponseHandler'} | ${ServiceDeskListApp.i18n.errorFetchingCounts}
    `('when there is an error $error', ({ responseHandler, message }) => {
      beforeEach(() => {
        wrapper = createComponent({
          [responseHandler]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
    });
  });

  describe('When providing token for labels', () => {
    it('passes function to fetchLatestLabels property if frontend caching is enabled', () => {
      wrapper = createComponent({
        provide: {
          glFeatures: {
            frontendCaching: true,
          },
        },
      });

      expect(typeof findLabelsToken().fetchLatestLabels).toBe('function');
    });

    it('passes null to fetchLatestLabels property if frontend caching is disabled', () => {
      wrapper = createComponent({
        provide: {
          glFeatures: {
            frontendCaching: false,
          },
        },
      });

      expect(findLabelsToken().fetchLatestLabels).toBe(null);
    });
  });
});
