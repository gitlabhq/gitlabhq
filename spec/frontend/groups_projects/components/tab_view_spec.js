import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import starredProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/starred_projects.query.graphql.json';
import inactiveProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/inactive_projects.query.graphql.json';
import personalProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/personal_projects.query.graphql.json';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import contributedProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import dashboardGroupsResponse from 'test_fixtures/groups/dashboard/index.json';
import dashboardGroupsWithChildrenResponse from 'test_fixtures/groups/dashboard/index_with_children.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import TabView from '~/groups_projects/components/tab_view.vue';
import { formatProjects } from '~/projects/your_work/utils';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListEmptyState from '~/vue_shared/components/projects_list/projects_list_empty_state.vue';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
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
import waitForPromises from 'helpers/wait_for_promises';
import { pageInfoMultiplePages, programmingLanguages } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

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
    filteredSearchTermKey: FILTERED_SEARCH_TERM_KEY,
    timestampType: TIMESTAMP_TYPE_CREATED_AT,
    programmingLanguages,
  };

  const createComponent = ({ handlers = [], propsData = {} } = {}) => {
    mockApollo = createMockApollo(handlers, resolvers(endpoint));

    wrapper = shallowMountExtended(TabView, {
      apolloProvider: mockApollo,
      propsData: { ...defaultPropsData, ...propsData },
    });

    apolloClient = mockApollo.defaultClient;
    jest.spyOn(apolloClient, 'resetStore');
  };

  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findEmptyState = () => wrapper.findComponent(ProjectsListEmptyState);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockApollo = null;
    apolloClient = null;
    mockAxios.restore();
  });

  describe.each`
    tab                | handler                                                                                     | expectedVariables                                                                          | expectedProjects
    ${CONTRIBUTED_TAB} | ${[CONTRIBUTED_TAB.query, jest.fn().mockResolvedValue(contributedProjectsGraphQlResponse)]} | ${{ contributed: true, starred: false, sort: defaultPropsData.sort.toUpperCase() }}        | ${contributedProjectsGraphQlResponse.data.currentUser.contributedProjects.nodes}
    ${PERSONAL_TAB}    | ${[PERSONAL_TAB.query, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)]}       | ${{ personal: true, membership: false, archived: 'EXCLUDE', sort: defaultPropsData.sort }} | ${personalProjectsGraphQlResponse.data.projects.nodes}
    ${MEMBER_TAB}      | ${[MEMBER_TAB.query, jest.fn().mockResolvedValue(membershipProjectsGraphQlResponse)]}       | ${{ personal: false, membership: true, archived: 'EXCLUDE', sort: defaultPropsData.sort }} | ${membershipProjectsGraphQlResponse.data.projects.nodes}
    ${STARRED_TAB}     | ${[STARRED_TAB.query, jest.fn().mockResolvedValue(starredProjectsGraphQlResponse)]}         | ${{ contributed: false, starred: true, sort: defaultPropsData.sort.toUpperCase() }}        | ${starredProjectsGraphQlResponse.data.currentUser.starredProjects.nodes}
    ${INACTIVE_TAB}    | ${[INACTIVE_TAB.query, jest.fn().mockResolvedValue(inactiveProjectsGraphQlResponse)]}       | ${{ personal: false, membership: true, archived: 'ONLY', sort: defaultPropsData.sort }}    | ${inactiveProjectsGraphQlResponse.data.projects.nodes}
  `(
    'onMount when route name is $tab.value',
    ({ tab, handler, expectedVariables, expectedProjects }) => {
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
            search: defaultPropsData.filters[defaultPropsData.filteredSearchTermKey],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
            ...expectedVariables,
          });
        });

        it('passes items to `ProjectsList` component', () => {
          expect(findProjectsList().props('items')).toEqual(formatProjects(expectedProjects));
        });

        it('passes `timestampType` prop to `ProjectsList` component', () => {
          expect(findProjectsList().props('timestampType')).toBe(TIMESTAMP_TYPE_CREATED_AT);
        });

        describe('when list emits refetch', () => {
          beforeEach(() => {
            findProjectsList().vm.$emit('refetch');
          });

          it('resets store and refetches list', () => {
            expect(apolloClient.resetStore).toHaveBeenCalled();
            expect(handler[1]).toHaveBeenCalledTimes(2);
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
            message:
              'An error occurred loading the projects. Please refresh the page to try again.',
            error,
            captureError: true,
          });
        });
      });
    },
  );

  describe('when tab.listComponent is NestedGroupsProjectsList', () => {
    beforeEach(() => {
      mockAxios.onGet(endpoint).replyOnce(200, dashboardGroupsResponse);
    });

    describe('when search is defined', () => {
      beforeEach(async () => {
        createComponent({ propsData: { tab: MEMBER_TAB_GROUPS } });
        await waitForPromises();
      });

      it('passes initialExpanded prop as true', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).props('initialExpanded')).toBe(true);
      });
    });

    describe('when search is empty', () => {
      beforeEach(async () => {
        createComponent({ propsData: { tab: MEMBER_TAB_GROUPS, filters: {} } });
        await waitForPromises();
      });

      it('passes initialExpanded prop as false', () => {
        expect(wrapper.findComponent(NestedGroupsProjectsList).props('initialExpanded')).toBe(
          false,
        );
      });
    });

    describe('when load-children event is fired', () => {
      const [group] = dashboardGroupsResponse;
      const [{ children }] = dashboardGroupsWithChildrenResponse;

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

        it('calls API with parent_id argument', () => {
          expect(mockAxios.history.get[1].params.parent_id).toBe(group.id);
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
            message:
              'An error occurred loading the projects. Please refresh the page to try again.',
            error: new Error('Network Error'),
            captureError: true,
          });
        });
      });
    });
  });

  describe('pagination', () => {
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
        expect(findPagination().exists()).toBe(false);
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
        expect(findPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        beforeEach(() => {
          findPagination().vm.$emit('next', mockEndCursor);
        });

        it('emits `page-change` event', () => {
          expect(wrapper.emitted('page-change')[0]).toEqual([
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
            archived: 'EXCLUDE',
            sort: defaultPropsData.sort,
            search: defaultPropsData.filters[defaultPropsData.filteredSearchTermKey],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
          });
        });
      });

      describe('when previous button is clicked', () => {
        beforeEach(() => {
          findPagination().vm.$emit('prev', mockStartCursor);
        });

        it('emits `page-change` event', () => {
          expect(wrapper.emitted('page-change')[0]).toEqual([
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
            archived: 'EXCLUDE',
            sort: defaultPropsData.sort,
            search: defaultPropsData.filters[defaultPropsData.filteredSearchTermKey],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
          });
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
});
