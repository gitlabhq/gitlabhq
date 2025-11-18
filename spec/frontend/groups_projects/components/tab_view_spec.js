import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlLoadingIcon, GlKeysetPagination, GlPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import starredProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/starred_projects.query.graphql.json';
import inactiveProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/inactive_projects.query.graphql.json';
import personalProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/personal_projects.query.graphql.json';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import contributedProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import dashboardGroupsResponse from 'test_fixtures/groups/dashboard/index.json';
import dashboardGroupsWithChildrenResponse from 'test_fixtures/groups/dashboard/index_with_children.json';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import TabView from '~/groups_projects/components/tab_view.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import {
  CONTRIBUTED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  STARRED_TAB,
  INACTIVE_TAB,
} from '~/projects/your_work/constants';
import { MEMBER_TAB as MEMBER_TAB_GROUPS } from '~/groups/your_work/constants';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/groups_projects/constants';
import { FILTERED_SEARCH_TERM_KEY } from '~/projects/filtered_search_and_sort/constants';
import { ACCESS_LEVEL_OWNER_INTEGER, ACCESS_LEVEL_OWNER_STRING } from '~/access_level/constants';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { resolvers } from '~/groups/your_work/graphql/resolvers';
import { markRaw } from '~/lib/utils/vue3compat/mark_raw';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { pageInfoMultiplePages, programmingLanguages } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const { bindInternalEventDocument } = useMockInternalEventsTracking();

describe('TabView', () => {
  let wrapper;
  let mockApollo;
  let mockAxios;
  let apolloClient;

  const endpoint = '/dashboard/groups.json';

  const defaultPropsData = {
    sort: 'name_desc',
    filters: {
      [FILTERED_SEARCH_TERM_KEY]: 'foo',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: '8',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: ACCESS_LEVEL_OWNER_INTEGER,
    },
    filtersAsQueryVariables: {
      programmingLanguageName: 'CoffeeScript',
      minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
    },
    search: 'foo',
    filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
    timestampType: TIMESTAMP_TYPE_CREATED_AT,
    programmingLanguages,
    eventTracking: {
      clickStat: 'click_stat_on_your_work_projects',
      hoverStat: 'hover_stat_on_your_work_projects',
      hoverVisibility: 'hover_visibility_icon_on_your_work_projects',
      clickItem: 'click_group_on_your_work_groups',
      clickItemAfterFilter: 'click_project_after_filter_on_your_work_projects',
      clickTopic: 'click_topic_on_your_work_projects',
    },
  };

  const createComponent = ({
    handlers = [],
    propsData = {},
    mountFn = shallowMountExtended,
  } = {}) => {
    mockApollo = createMockApollo(handlers, resolvers(endpoint));

    wrapper = mountFn(TabView, {
      apolloProvider: mockApollo,
      propsData: { ...defaultPropsData, ...propsData },
    });

    apolloClient = mockApollo.defaultClient;
    jest.spyOn(apolloClient, 'clearStore');
  };

  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findOffsetPagination = () => wrapper.findComponent(GlPagination);
  const findEmptyState = () => wrapper.findComponent(ResourceListsEmptyState);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockApollo = null;
    apolloClient = null;
    mockAxios.restore();
  });

  describe.each`
    tab                | handler                                                                                     | expectedVariables                                                                    | expectedProjects
    ${CONTRIBUTED_TAB} | ${[CONTRIBUTED_TAB.query, jest.fn().mockResolvedValue(contributedProjectsGraphQlResponse)]} | ${{ contributed: true, starred: false, sort: defaultPropsData.sort.toUpperCase() }}  | ${contributedProjectsGraphQlResponse.data.currentUser.contributedProjects}
    ${PERSONAL_TAB}    | ${[PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)]}       | ${{ personal: true, membership: false, active: true, sort: defaultPropsData.sort }}  | ${personalProjectsGraphQlResponse.data.projects}
    ${MEMBER_TAB}      | ${[MEMBER_TAB.query, jest.fn().mockResolvedValue(membershipProjectsGraphQlResponse)]}       | ${{ personal: false, membership: true, active: true, sort: defaultPropsData.sort }}  | ${membershipProjectsGraphQlResponse.data.projects}
    ${STARRED_TAB}     | ${[STARRED_TAB.query, jest.fn().mockResolvedValue(starredProjectsGraphQlResponse)]}         | ${{ contributed: false, starred: true, sort: defaultPropsData.sort.toUpperCase() }}  | ${starredProjectsGraphQlResponse.data.currentUser.starredProjects}
    ${INACTIVE_TAB}    | ${[INACTIVE_TAB.query, jest.fn().mockResolvedValue(inactiveProjectsGraphQlResponse)]}       | ${{ personal: false, membership: true, active: false, sort: defaultPropsData.sort }} | ${inactiveProjectsGraphQlResponse.data.projects}
  `(
    'onMount when route name is $tab.value',
    ({ tab, handler, expectedVariables, expectedProjects: { nodes, count } }) => {
      describe('when GraphQL request is loading', () => {
        beforeEach(() => {
          createComponent({ handlers: [handler], propsData: { tab } });
        });

        it('shows loading icon', () => {
          expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        });
      });

      describe('when GraphQL request is successful', () => {
        beforeEach(async () => {
          createComponent({ handlers: [handler], propsData: { tab } });
          await waitForPromises();
        });

        it('calls GraphQL query with correct variables', async () => {
          await waitForPromises();

          expect(handler[1]).toHaveBeenCalledWith({
            last: null,
            first: DEFAULT_PER_PAGE,
            before: null,
            after: null,
            search: defaultPropsData.search,
            ...defaultPropsData.filtersAsQueryVariables,
            ...expectedVariables,
          });
        });

        it('emits query-complete event', () => {
          expect(wrapper.emitted('query-complete')).toEqual([[]]);
        });

        it('emits update-count event', () => {
          expect(wrapper.emitted('update-count')).toEqual([[tab, count]]);
        });

        it('passes items to `ProjectsList` component', () => {
          expect(findProjectsList().props('items')).toEqual(formatGraphQLProjects(nodes));
        });

        it('passes `timestampType` prop to `ProjectsList` component', () => {
          expect(findProjectsList().props('timestampType')).toBe(TIMESTAMP_TYPE_CREATED_AT);
        });

        describe('when list emits refetch', () => {
          beforeEach(() => {
            findProjectsList().vm.$emit('refetch');
          });

          it('clears store and refetches list', async () => {
            expect(apolloClient.clearStore).toHaveBeenCalled();
            await waitForPromises();
            expect(handler[1]).toHaveBeenCalledTimes(2);
          });

          it('emits refetch event', async () => {
            await waitForPromises();
            expect(wrapper.emitted('refetch')).toEqual([[]]);
          });
        });
      });

      describe('when GraphQL request is not successful', () => {
        const error = new Error();

        beforeEach(async () => {
          createComponent({
            handlers: [[handler[0], jest.fn().mockRejectedValue(error)]],
            propsData: { tab },
          });
          await waitForPromises();
        });

        it('displays error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: "Your projects couldn't be loaded. Refresh the page to try again.",
            error,
            captureError: true,
          });
        });
      });
    },
  );

  describe('when queryErrorMessage is not defined', () => {
    const error = new Error();

    beforeEach(async () => {
      createComponent({
        handlers: [[CONTRIBUTED_TAB.query, jest.fn().mockRejectedValue(error)]],
        propsData: { tab: { ...CONTRIBUTED_TAB, queryErrorMessage: undefined } },
      });
      await waitForPromises();
    });

    it('displays error alert with fallback message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred. Refresh the page to try again.',
        error,
        captureError: true,
      });
    });
  });

  describe('when tab.listComponent is NestedGroupsProjectsList', () => {
    describe('when search is defined', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
        createComponent({
          propsData: { tab: MEMBER_TAB_GROUPS },
        });
        await waitForPromises();
      });

      it('passes expandedOverride prop as true', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).props('expandedOverride')).toBe(
          true,
        );
      });
    });

    describe('when GraphQL query is cached and search is cleared', () => {
      // We need to globally render components to avoid circular references
      // https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
      Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
      Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsWithChildrenResponse);
        createComponent({
          propsData: {
            tab: { ...MEMBER_TAB_GROUPS, listComponent: markRaw(NestedGroupsProjectsList) },
            search: '',
          },
          mountFn: mountExtended,
        });
        await waitForPromises();

        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsWithChildrenResponse);
        await wrapper.setProps({ search: 'foo' });
        await waitForPromises();

        await wrapper.setProps({ search: '' });
      });

      it('collapses groups that were expanded due to searching', () => {
        expect(
          wrapper
            .findByTestId('nested-groups-project-list-item-toggle-button')
            .attributes('aria-expanded'),
        ).toBe('false');
      });
    });

    describe('when search is empty', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
        createComponent({
          propsData: {
            tab: MEMBER_TAB_GROUPS,
            filters: {},
            filtersAsQueryVariables: {},
            search: '',
          },
        });
        await waitForPromises();
      });

      it('passes expandedOverride prop as false', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).props('expandedOverride')).toBe(
          false,
        );
      });
    });

    describe('when load-children event is fired', () => {
      const [group] = dashboardGroupsResponse;
      const [{ children }] = dashboardGroupsWithChildrenResponse;

      beforeEach(() => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
      });

      describe('when API request is loading', () => {
        beforeEach(async () => {
          createComponent({ propsData: { tab: MEMBER_TAB_GROUPS } });
          await waitForPromises();
          mockAxios.onGet(endpoint).replyOnce(200, [{ ...group, children }]);
          wrapper.findComponent(NestedGroupsProjectsList).vm.$emit('load-children', group.id);
        });

        it('sets item as loading', () => {
          expect(
            wrapper.findComponent(NestedGroupsProjectsList).props('items')[0].childrenLoading,
          ).toBe(true);
        });

        it('unsets item as loading after API request resolves', async () => {
          await waitForPromises();

          expect(
            wrapper.findComponent(NestedGroupsProjectsList).props('items')[0].childrenLoading,
          ).toBe(false);
        });
      });

      describe('when API request is successful', () => {
        beforeEach(async () => {
          createComponent({ propsData: { tab: MEMBER_TAB_GROUPS } });
          await waitForPromises();
          mockAxios.onGet(endpoint).replyOnce(200, [{ ...group, children }]);
          wrapper.findComponent(NestedGroupsProjectsList).vm.$emit('load-children', group.id);
          await waitForPromises();
        });

        it('calls API with parent_id and tab variables', () => {
          expect(mockAxios.history.get[1].params).toEqual({
            parent_id: group.id,
            ...MEMBER_TAB_GROUPS.variables,
          });
        });

        it('updates children of item', () => {
          expect(
            wrapper
              .findComponent(NestedGroupsProjectsList)
              .props('items')[0]
              .children.map((child) => child.id),
          ).toEqual(children.map((item) => item.id));
        });
      });

      describe('when API request is not successful', () => {
        beforeEach(async () => {
          createComponent({ propsData: { tab: MEMBER_TAB_GROUPS } });
          await waitForPromises();
          mockAxios.onGet(endpoint).networkError();
          wrapper.findComponent(NestedGroupsProjectsList).vm.$emit('load-children', group.id);
          await waitForPromises();
        });

        it('displays error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: "Your groups couldn't be loaded. Refresh the page to try again.",
            error: new Error('Network Error'),
            captureError: true,
          });
        });
      });
    });
  });

  describe('keyset pagination', () => {
    const propsData = { tab: PERSONAL_TAB };

    describe('when there is one page of projects', () => {
      beforeEach(async () => {
        createComponent({
          handlers: [
            [PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)],
          ],
          propsData,
        });
        await waitForPromises();
      });

      it('does not render pagination', () => {
        expect(findKeysetPagination().exists()).toBe(false);
      });
    });

    describe('when there are multiple pages of projects', () => {
      const mockEndCursor = 'mockEndCursor';
      const mockStartCursor = 'mockStartCursor';
      const handler = [
        PERSONAL_TAB.query,
        jest.fn().mockResolvedValue({
          data: {
            projects: {
              nodes: personalProjectsGraphQlResponse.data.projects.nodes,
              pageInfo: pageInfoMultiplePages,
              count: personalProjectsGraphQlResponse.data.projects.count,
            },
          },
        }),
      ];

      beforeEach(async () => {
        createComponent({
          handlers: [handler],
          propsData,
        });
        await waitForPromises();
      });

      it('renders pagination', () => {
        expect(findKeysetPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        beforeEach(() => {
          findKeysetPagination().vm.$emit('next', mockEndCursor);
        });

        it('emits `keyset-page-change` event', () => {
          expect(wrapper.emitted('keyset-page-change')[0]).toEqual([
            {
              endCursor: mockEndCursor,
              startCursor: null,
            },
          ]);
        });
      });

      describe('when `endCursor` prop is changed', () => {
        beforeEach(async () => {
          wrapper.setProps({ endCursor: mockEndCursor });
          await waitForPromises();
        });

        it('calls query with correct variables', () => {
          expect(handler[1]).toHaveBeenCalledWith({
            after: mockEndCursor,
            before: null,
            first: DEFAULT_PER_PAGE,
            last: null,
            personal: true,
            membership: false,
            active: true,
            sort: defaultPropsData.sort,
            search: defaultPropsData.filters[defaultPropsData.filteredSearchTermKey],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
          });
        });
      });

      describe('when previous button is clicked', () => {
        beforeEach(() => {
          findKeysetPagination().vm.$emit('prev', mockStartCursor);
        });

        it('emits `keyset-page-change` event', () => {
          expect(wrapper.emitted('keyset-page-change')[0]).toEqual([
            {
              endCursor: null,
              startCursor: mockStartCursor,
            },
          ]);
        });
      });

      describe('when `startCursor` prop is changed', () => {
        beforeEach(async () => {
          wrapper.setProps({ startCursor: mockStartCursor });
          await waitForPromises();
        });

        it('calls query with correct variables', () => {
          expect(handler[1]).toHaveBeenCalledWith({
            after: null,
            before: mockStartCursor,
            first: null,
            last: DEFAULT_PER_PAGE,
            personal: true,
            membership: false,
            active: true,
            sort: defaultPropsData.sort,
            search: defaultPropsData.filters[defaultPropsData.filteredSearchTermKey],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
          });
        });
      });
    });
  });

  describe('offset pagination', () => {
    const propsData = { tab: MEMBER_TAB_GROUPS };

    describe('when there is one page', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse, {
          'x-per-page': 10,
          'x-page': 1,
          'x-total': 9,
          'x-total-pages': 1,
          'x-next-page': null,
          'x-prev-page': null,
        });
        createComponent({
          propsData,
        });
        await waitForPromises();
      });

      it('does not render pagination', () => {
        expect(findOffsetPagination().exists()).toBe(false);
      });
    });

    describe('when there are multiple pages', () => {
      beforeEach(async () => {
        mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse, {
          'x-per-page': 10,
          'x-page': 2,
          'x-total': 21,
          'x-total-pages': 3,
          'x-next-page': 3,
          'x-prev-page': 1,
        });

        createComponent({
          propsData,
        });
        await waitForPromises();
      });

      it('renders pagination', () => {
        expect(findOffsetPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        beforeEach(() => {
          findOffsetPagination().vm.$emit('input', 3);
        });

        it('emits `offset-page-change` event', () => {
          expect(wrapper.emitted('offset-page-change')[0]).toEqual([3]);
        });
      });

      describe('when previous button is clicked', () => {
        beforeEach(() => {
          findOffsetPagination().vm.$emit('input', 1);
        });

        it('emits `offset-page-change` event', () => {
          expect(wrapper.emitted('offset-page-change')[0]).toEqual([1]);
        });
      });

      describe('when `page` prop is changed', () => {
        beforeEach(async () => {
          wrapper.setProps({ page: 3 });
          await waitForPromises();
        });

        it('calls API with page argument', () => {
          expect(mockAxios.history.get[1].params.page).toBe(3);
        });
      });
    });
  });

  describe('empty state', () => {
    describe('when there are no results', () => {
      beforeEach(async () => {
        createComponent({
          handlers: [[CONTRIBUTED_TAB.query, jest.fn().mockResolvedValue({ nodes: [] })]],
          propsData: { tab: CONTRIBUTED_TAB },
        });
        await waitForPromises();
      });

      it('renders an empty state and passes title and description prop', () => {
        expect(findEmptyState().props('title')).toBe(
          CONTRIBUTED_TAB.emptyStateComponentProps.title,
        );
        expect(findEmptyState().props('description')).toBe(
          CONTRIBUTED_TAB.emptyStateComponentProps.description,
        );
      });
    });

    describe('when there are results', () => {
      beforeEach(async () => {
        createComponent({
          handlers: [
            [PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)],
          ],
          propsData: { tab: PERSONAL_TAB },
        });
        await waitForPromises();
      });

      it('does not render an empty state', () => {
        expect(findEmptyState().exists()).toBe(false);
      });
    });
  });

  describe('event tracking', () => {
    let trackEventSpy;

    const setup = async () => {
      createComponent({
        handlers: [
          [PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)],
        ],
        propsData: { tab: PERSONAL_TAB },
      });
      await waitForPromises();
      trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;
    };

    describe('when visibility is hovered', () => {
      beforeEach(async () => {
        await setup();
        findProjectsList().vm.$emit('hover-visibility', 'private');
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.hoverVisibility,
          { label: 'private' },
          undefined,
        );
      });
    });

    describe('when stat is hovered', () => {
      beforeEach(async () => {
        await setup();
        findProjectsList().vm.$emit('hover-stat', 'stars-count');
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.hoverStat,
          { label: 'stars-count' },
          undefined,
        );
      });
    });

    describe('when stat is clicked', () => {
      beforeEach(async () => {
        await setup();
        findProjectsList().vm.$emit('click-stat', 'stars-count');
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickStat,
          { label: 'stars-count' },
          undefined,
        );
      });
    });

    describe('when topic is clicked', () => {
      beforeEach(async () => {
        await setup();
        findProjectsList().vm.$emit('click-topic');
      });

      it('tracks event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickTopic,
          {},
          undefined,
        );
      });
    });

    describe('when avatar is clicked with filter', () => {
      beforeEach(async () => {
        await setup();
        findProjectsList().vm.$emit('click-avatar');
      });

      it('tracks click item event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickItem,
          {
            label: PERSONAL_TAB.value,
          },
          undefined,
        );
      });

      it('tracks click item after filter event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickItemAfterFilter,
          {
            label: PERSONAL_TAB.value,
            property: JSON.stringify({
              search: 'user provided value',
              language: '8',
              min_access_level: 50,
            }),
          },
          undefined,
        );
      });
    });

    describe('when avatar is clicked without filter', () => {
      beforeEach(async () => {
        createComponent({
          handlers: [
            [PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)],
          ],
          propsData: { tab: PERSONAL_TAB, filters: {}, search: '' },
        });
        await waitForPromises();
        trackEventSpy = bindInternalEventDocument(wrapper.element).trackEventSpy;
        findProjectsList().vm.$emit('click-avatar');
      });

      it('tracks click item event', () => {
        expect(trackEventSpy).toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickItem,
          {
            label: PERSONAL_TAB.value,
          },
          undefined,
        );
      });

      it('does not track click item after filter event', () => {
        expect(trackEventSpy).not.toHaveBeenCalledWith(
          defaultPropsData.eventTracking.clickItemAfterFilter,
        );
      });
    });
  });
});
