import Vue from 'vue';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import starredProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/starred_projects.query.graphql.json';
import inactiveProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/inactive_projects.query.graphql.json';
import personalProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/personal_projects.query.graphql.json';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import contributedProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TabView from '~/projects/your_work/components/tab_view.vue';
import { formatProjects } from '~/projects/your_work/utils';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListEmptyState from '~/vue_shared/components/projects_list/projects_list_empty_state.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { createAlert } from '~/alert';
import {
  CONTRIBUTED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  STARRED_TAB,
  INACTIVE_TAB,
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '~/projects/your_work/constants';
import { FILTERED_SEARCH_TERM_KEY } from '~/projects/filtered_search_and_sort/constants';
import { ACCESS_LEVEL_OWNER_INTEGER, ACCESS_LEVEL_OWNER_STRING } from '~/access_level/constants';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { pageInfoMultiplePages, programmingLanguages } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('TabView', () => {
  let wrapper;
  let mockApollo;
  let apolloClient;

  const defaultPropsData = {
    sort: 'name_desc',
    filters: {
      [FILTERED_SEARCH_TERM_KEY]: 'foo',
      [FILTERED_SEARCH_TOKEN_LANGUAGE]: '8',
      [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: ACCESS_LEVEL_OWNER_INTEGER,
    },
    timestampType: TIMESTAMP_TYPE_CREATED_AT,
  };

  const createComponent = ({ handler, propsData = {} } = {}) => {
    mockApollo = createMockApollo([handler]);

    wrapper = shallowMountExtended(TabView, {
      apolloProvider: mockApollo,
      propsData: { ...defaultPropsData, ...propsData },
      provide: { programmingLanguages },
    });

    apolloClient = mockApollo.defaultClient;
    jest.spyOn(apolloClient, 'resetStore');
  };

  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findEmptyState = () => wrapper.findComponent(ProjectsListEmptyState);

  afterEach(() => {
    mockApollo = null;
    apolloClient = null;
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
          createComponent({ handler, propsData: { tab } });
        });

        it('shows loading icon', () => {
          expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        });
      });

      describe('when GraphQL request is successful', () => {
        beforeEach(async () => {
          createComponent({ handler, propsData: { tab } });
          await waitForPromises();
        });

        it('calls GraphQL query with correct variables', async () => {
          await waitForPromises();

          expect(handler[1]).toHaveBeenCalledWith({
            last: null,
            first: DEFAULT_PER_PAGE,
            before: null,
            after: null,
            search: defaultPropsData.filters[FILTERED_SEARCH_TERM_KEY],
            programmingLanguageName: 'CoffeeScript',
            minAccessLevel: ACCESS_LEVEL_OWNER_STRING,
            ...expectedVariables,
          });
        });

        it('passes projects to `ProjectsList` component', () => {
          expect(findProjectsList().props('projects')).toEqual(formatProjects(expectedProjects));
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
            handler: [handler[0], jest.fn().mockRejectedValue(error)],
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

  describe('pagination', () => {
    const propsData = { tab: PERSONAL_TAB };

    describe('when there is one page of projects', () => {
      beforeEach(async () => {
        createComponent({
          handler: [
            PERSONAL_TAB.query,
            jest.fn().mockResolvedValue(personalProjectsGraphQlResponse),
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
          handler,
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
            search: defaultPropsData.filters[FILTERED_SEARCH_TERM_KEY],
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
            search: defaultPropsData.filters[FILTERED_SEARCH_TERM_KEY],
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
          handler: [CONTRIBUTED_TAB.query, jest.fn().mockResolvedValue({ nodes: [] })],
          propsData: { tab: CONTRIBUTED_TAB },
        });
        await waitForPromises();
      });

      it('renders an empty state and passes title and description prop', () => {
        expect(findEmptyState().props('title')).toBe(CONTRIBUTED_TAB.emptyState.title);
        expect(findEmptyState().props('description')).toBe(CONTRIBUTED_TAB.emptyState.description);
      });
    });

    describe('when there are results', () => {
      beforeEach(async () => {
        createComponent({
          handler: [
            PERSONAL_TAB.query,
            jest.fn().mockResolvedValue(personalProjectsGraphQlResponse),
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
