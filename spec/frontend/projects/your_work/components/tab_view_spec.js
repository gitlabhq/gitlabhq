import Vue from 'vue';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import starredProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/starred_projects.query.graphql.json';
import inactiveProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/inactive_projects.query.graphql.json';
import personalProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/personal_projects.query.graphql.json';
import membershipProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/membership_projects.query.graphql.json';
import contributedProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TabView from '~/projects/your_work/components/tab_view.vue';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import contributedProjectsQuery from '~/projects/your_work/graphql/queries/contributed_projects.query.graphql';
import personalProjectsQuery from '~/projects/your_work/graphql/queries/personal_projects.query.graphql';
import membershipProjectsQuery from '~/projects/your_work/graphql/queries/membership_projects.query.graphql';
import starredProjectsQuery from '~/projects/your_work/graphql/queries/starred_projects.query.graphql';
import inactiveProjectsQuery from '~/projects/your_work/graphql/queries/inactive_projects.query.graphql';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/utils';
import { createAlert } from '~/alert';
import {
  CONTRIBUTED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  STARRED_TAB,
  INACTIVE_TAB,
} from '~/projects/your_work/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { pageInfoMultiplePages } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('TabView', () => {
  let wrapper;
  let mockApollo;

  const createComponent = ({ handler, propsData }) => {
    mockApollo = createMockApollo([handler]);

    wrapper = mountExtended(TabView, {
      apolloProvider: mockApollo,
      propsData,
    });
  };

  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  afterEach(() => {
    mockApollo = null;
  });

  describe.each`
    tab                | handler                                                                                        | expectedProjects
    ${CONTRIBUTED_TAB} | ${[contributedProjectsQuery, jest.fn().mockResolvedValue(contributedProjectsGraphQlResponse)]} | ${contributedProjectsGraphQlResponse.data.currentUser.contributedProjects.nodes}
    ${PERSONAL_TAB}    | ${[personalProjectsQuery, jest.fn().mockResolvedValue(personalProjectsGraphQlResponse)]}       | ${personalProjectsGraphQlResponse.data.projects.nodes}
    ${MEMBER_TAB}      | ${[membershipProjectsQuery, jest.fn().mockResolvedValue(membershipProjectsGraphQlResponse)]}   | ${membershipProjectsGraphQlResponse.data.projects.nodes}
    ${STARRED_TAB}     | ${[starredProjectsQuery, jest.fn().mockResolvedValue(starredProjectsGraphQlResponse)]}         | ${starredProjectsGraphQlResponse.data.currentUser.starredProjects.nodes}
    ${INACTIVE_TAB}    | ${[inactiveProjectsQuery, jest.fn().mockResolvedValue(inactiveProjectsGraphQlResponse)]}       | ${inactiveProjectsGraphQlResponse.data.projects.nodes}
  `('onMount when route name is $tab.value', ({ tab, handler, expectedProjects }) => {
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
        });
      });

      it('passes projects to `ProjectsList` component', () => {
        expect(findProjectsList().props('projects')).toEqual(
          formatGraphQLProjects(expectedProjects),
        );
      });

      describe('when project delete is complete', () => {
        beforeEach(() => {
          findProjectsList().vm.$emit('delete-complete');
        });

        it('refetches list', () => {
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
          message: 'An error occurred loading the projects. Please refresh the page to try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('pagination', () => {
    const propsData = { tab: PERSONAL_TAB };

    describe('when there is one page of projects', () => {
      beforeEach(async () => {
        createComponent({
          handler: [
            personalProjectsQuery,
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
        personalProjectsQuery,
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
          });
        });
      });
    });
  });
});
