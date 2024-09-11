import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import contributedProjectsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/contributed_projects.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TabView from '~/projects/your_work/components/tab_view.vue';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import contributedProjectsQuery from '~/projects/your_work/graphql/queries/contributed_projects.query.graphql';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/utils';
import { createAlert } from '~/alert';
import { CONTRIBUTED_TAB } from 'ee_else_ce/projects/your_work/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

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

  afterEach(() => {
    mockApollo = null;
  });

  describe.each`
    tab                | handler                                                                                        | expectedProjects
    ${CONTRIBUTED_TAB} | ${[contributedProjectsQuery, jest.fn().mockResolvedValue(contributedProjectsGraphQlResponse)]} | ${contributedProjectsGraphQlResponse.data.currentUser.contributedProjects.nodes}
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
});
