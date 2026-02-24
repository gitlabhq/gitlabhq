import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import ProjectsList from '~/homepage/components/projects_list.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import userProjectsQuery from '~/homepage/graphql/queries/user_projects.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_PROJECTS,
  TRACKING_PROPERTY_QUICK_ACCESS_PROJECT_LINK,
} from '~/homepage/tracking_constants';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

describe('ProjectsList', () => {
  let wrapper;

  const mockUserProjectsResponse = {
    data: {
      frecentProjects: [
        {
          id: 'gid://gitlab/Project/1',
          name: 'GitLab',
          namespace: 'gitlab-org / GitLab',
          webPath: '/gitlab-org/gitlab',
          avatarUrl: null,
        },
        {
          id: 'gid://gitlab/Project/2',
          name: 'Runner',
          namespace: 'gitlab-org / Runner',
          webPath: '/gitlab-org/gitlab-runner',
          avatarUrl: 'https://example.com/avatar.png',
        },
      ],
      currentUser: {
        id: 'gid://gitlab/User/1',
        starredProjects: {
          nodes: [
            {
              id: 'gid://gitlab/Project/3',
              name: 'Gitaly',
              namespace: 'gitlab-org / Gitaly',
              webPath: '/gitlab-org/gitaly',
              avatarUrl: null,
            },
          ],
        },
      },
    },
  };

  const userProjectsQuerySuccessHandler = jest.fn().mockResolvedValue(mockUserProjectsResponse);
  const userProjectsQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const createComponent = ({
    userProjectsHandler = userProjectsQuerySuccessHandler,
    selectedSources = ['FRECENT'],
  } = {}) => {
    const mockApollo = createMockApollo([[userProjectsQuery, userProjectsHandler]]);

    wrapper = shallowMountExtended(ProjectsList, {
      apolloProvider: mockApollo,
      propsData: {
        selectedSources,
      },
    });
  };

  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findErrorMessage = () =>
    wrapper.findByText('Your projects are not available. Please refresh the page to try again.');
  const findEmptyState = () =>
    wrapper.findByText('No projects match your selected display options.');
  const findProjectsList = () => wrapper.find('ul');
  const findProjectLinks = () => wrapper.findAllByTestId('quick-access-project-link');
  const findProjectAvatars = () => wrapper.findAllComponents(ProjectAvatar);
  const findTooltipComponents = () => wrapper.findAllComponents(TooltipOnTruncate);
  const findFrequentlyVisitedMessage = () =>
    wrapper.findByText('Displaying frequently visited projects');

  describe('loading state', () => {
    it('shows skeleton loaders while fetching data', () => {
      createComponent();

      expect(findSkeletonLoaders()).toHaveLength(10);
      expect(findProjectsList().exists()).toBe(false);
    });

    it('hides skeleton loaders after data is fetched', async () => {
      createComponent();
      await waitForPromises();

      expect(findSkeletonLoaders()).toHaveLength(0);
      expect(findProjectsList().exists()).toBe(true);
    });
  });

  describe('error state', () => {
    beforeEach(async () => {
      createComponent({ userProjectsHandler: userProjectsQueryErrorHandler });
      await waitForPromises();
    });

    it('shows error message when query fails', () => {
      expect(findErrorMessage().exists()).toBe(true);
    });

    it('captures error with Sentry when query fails', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'GraphQL Error',
        }),
      );
    });

    it('does not show projects list during error state', () => {
      expect(findProjectsList().exists()).toBe(false);
    });
  });

  describe('empty state and footer message', () => {
    it('shows empty state when there are no projects', async () => {
      const emptyResponse = {
        data: {
          frecentProjects: [],
          currentUser: {
            id: 'gid://gitlab/User/1',
            starredProjects: {
              nodes: [],
            },
          },
        },
      };

      const emptyQueryHandler = jest.fn().mockResolvedValue(emptyResponse);
      createComponent({ userProjectsHandler: emptyQueryHandler });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findProjectsList().exists()).toBe(false);
      expect(findFrequentlyVisitedMessage().exists()).toBe(false);
    });

    it('does not show footer message during error state', async () => {
      createComponent({ userProjectsHandler: userProjectsQueryErrorHandler });
      await waitForPromises();

      expect(findFrequentlyVisitedMessage().exists()).toBe(false);
    });
  });

  describe('project source filtering', () => {
    it('shows only frecent projects when selectedSources is FRECENT', async () => {
      createComponent({ selectedSources: ['FRECENT'] });
      await waitForPromises();

      const links = findProjectLinks();
      expect(links).toHaveLength(2);
      expect(links.at(0).attributes('href')).toBe('/gitlab-org/gitlab');
      expect(links.at(1).attributes('href')).toBe('/gitlab-org/gitlab-runner');
    });

    it('shows only starred projects when selectedSources is STARRED', async () => {
      createComponent({ selectedSources: ['STARRED'] });
      await waitForPromises();

      const links = findProjectLinks();
      expect(links).toHaveLength(1);
      expect(links.at(0).attributes('href')).toBe('/gitlab-org/gitaly');
    });

    it('shows both frecent and starred projects when both are selected', async () => {
      createComponent({ selectedSources: ['FRECENT', 'STARRED'] });
      await waitForPromises();

      const links = findProjectLinks();
      expect(links).toHaveLength(3);
    });
  });

  describe('GraphQL query', () => {
    it('makes the correct GraphQL query', () => {
      createComponent();

      expect(userProjectsQuerySuccessHandler).toHaveBeenCalled();
    });
  });

  describe('projects rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders frecent projects with correct URLs and avatars', () => {
      const links = findProjectLinks();

      expect(links).toHaveLength(2);
      expect(links.at(0).attributes('href')).toBe('/gitlab-org/gitlab');
      expect(links.at(1).attributes('href')).toBe('/gitlab-org/gitlab-runner');
      expect(findProjectAvatars()).toHaveLength(2);
    });

    it('renders project names with tooltips', () => {
      const tooltips = findTooltipComponents();

      expect(tooltips).toHaveLength(2);
      expect(tooltips.at(0).text()).toContain('GitLab · gitlab-org / GitLab');
      expect(tooltips.at(1).text()).toBe('Runner · gitlab-org / Runner');
    });
  });

  describe('deduplication logic', () => {
    it('removes duplicate projects when same project appears in both sources', async () => {
      const deduplicateHandler = jest.fn().mockResolvedValue({
        data: {
          ...mockUserProjectsResponse.data,
          currentUser: {
            ...mockUserProjectsResponse.data.currentUser,
            starredProjects: {
              nodes: [
                mockUserProjectsResponse.data.frecentProjects[0], // Duplicate
                mockUserProjectsResponse.data.currentUser.starredProjects.nodes[0],
              ],
            },
          },
        },
      });

      createComponent({
        userProjectsHandler: deduplicateHandler,
        selectedSources: ['FRECENT', 'STARRED'],
      });
      await waitForPromises();

      expect(findProjectLinks()).toHaveLength(3);
    });
  });

  describe('refresh functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refreshes on becoming visible again', async () => {
      const refetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.projects, 'refetch');

      await wrapper.trigger('visible');

      expect(refetchSpy).toHaveBeenCalled();
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('tracks clicks on project links', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const link = findProjectLinks().at(0);
      link.element.addEventListener('click', (e) => e.preventDefault());
      link.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_PROJECTS,
          property: TRACKING_PROPERTY_QUICK_ACCESS_PROJECT_LINK,
        },
        undefined,
      );
    });
  });
});
