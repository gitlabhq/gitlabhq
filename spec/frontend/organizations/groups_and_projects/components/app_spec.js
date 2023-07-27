import App from '~/organizations/groups_and_projects/components/app.vue';
import GroupsPage from '~/organizations/groups_and_projects/components/groups_page.vue';
import ProjectsPage from '~/organizations/groups_and_projects/components/projects_page.vue';
import {
  DISPLAY_QUERY_GROUPS,
  DISPLAY_QUERY_PROJECTS,
} from '~/organizations/groups_and_projects/constants';
import { createRouter } from '~/organizations/groups_and_projects';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GroupsAndProjectsApp', () => {
  const router = createRouter();
  const routerMock = {
    push: jest.fn(),
  };
  let wrapper;

  const createComponent = ({ routeQuery = {} } = {}) => {
    wrapper = shallowMountExtended(App, {
      router,
      mocks: { $route: { path: '/', query: routeQuery }, $router: routerMock },
    });
  };

  describe.each`
    display                   | expectedComponent
    ${null}                   | ${GroupsPage}
    ${DISPLAY_QUERY_GROUPS}   | ${GroupsPage}
    ${DISPLAY_QUERY_PROJECTS} | ${ProjectsPage}
  `('when `display` query string is $display', ({ display, expectedComponent }) => {
    it('renders expected component', () => {
      createComponent({ routeQuery: { display } });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    });
  });
});
