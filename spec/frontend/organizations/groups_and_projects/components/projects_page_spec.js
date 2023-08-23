import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ProjectsPage from '~/organizations/groups_and_projects/components/projects_page.vue';
import { formatProjects } from '~/organizations/groups_and_projects/utils';
import resolvers from '~/organizations/groups_and_projects/graphql/resolvers';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { organizationProjects } from '~/organizations/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
jest.useFakeTimers();

describe('ProjectsPage', () => {
  let wrapper;
  let mockApollo;

  const createComponent = ({ mockResolvers = resolvers } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(ProjectsPage, { apolloProvider: mockApollo });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('when API call is loading', () => {
    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
        },
      };

      createComponent({ mockResolvers });
    });

    it('renders loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders `ProjectsList` component and passes correct props', async () => {
      jest.runAllTimers();
      await waitForPromises();

      expect(wrapper.findComponent(ProjectsList).props()).toEqual({
        projects: formatProjects(organizationProjects.nodes),
        showProjectIcon: true,
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(() => {
      const mockResolvers = {
        Query: {
          organization: jest.fn().mockRejectedValueOnce(error),
        },
      };

      createComponent({ mockResolvers });
    });

    it('displays error alert', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: ProjectsPage.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });
});
