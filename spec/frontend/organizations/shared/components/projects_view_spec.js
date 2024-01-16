import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import { formatProjects } from '~/organizations/shared/utils';
import resolvers from '~/organizations/shared/graphql/resolvers';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { organizationProjects } from '~/organizations/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
jest.useFakeTimers();

describe('ProjectsView', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    projectsEmptyStateSvgPath: 'illustrations/empty-state/empty-projects-md.svg',
    newProjectPath: '/projects/new',
  };

  const defaultPropsData = {
    listItemClass: 'gl-px-5',
  };

  const createComponent = ({ mockResolvers = resolvers, propsData = {} } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(ProjectsView, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
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
    describe('when there are no projects', () => {
      it('renders empty state without buttons by default', async () => {
        const mockResolvers = {
          Query: {
            organization: jest.fn().mockResolvedValueOnce({
              projects: { nodes: [] },
            }),
          },
        };
        createComponent({ mockResolvers });

        jest.runAllTimers();
        await waitForPromises();

        expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
          title: "You don't have any projects yet.",
          description:
            'Projects are where you can store your code, access issues, wiki, and other features of Gitlab.',
          svgHeight: 144,
          svgPath: defaultProvide.projectsEmptyStateSvgPath,
          primaryButtonLink: null,
          primaryButtonText: null,
        });
      });

      describe('when `shouldShowEmptyStateButtons` is `true` and `projectsEmptyStateSvgPath` is set', () => {
        it('renders empty state with buttons', async () => {
          const mockResolvers = {
            Query: {
              organization: jest.fn().mockResolvedValueOnce({
                projects: { nodes: [] },
              }),
            },
          };
          createComponent({ mockResolvers, propsData: { shouldShowEmptyStateButtons: true } });

          jest.runAllTimers();
          await waitForPromises();

          expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
            primaryButtonLink: defaultProvide.newProjectPath,
            primaryButtonText: 'New project',
          });
        });
      });
    });

    describe('when there are projects', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders `ProjectsList` component and passes correct props', async () => {
        jest.runAllTimers();
        await waitForPromises();

        expect(wrapper.findComponent(ProjectsList).props()).toEqual({
          projects: formatProjects(organizationProjects.nodes),
          showProjectIcon: true,
          listItemClass: defaultPropsData.listItemClass,
        });
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
        message: ProjectsView.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });
});
