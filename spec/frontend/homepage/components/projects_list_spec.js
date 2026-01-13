import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectsList from '~/homepage/components/projects_list.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import FrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

describe('ProjectsList', () => {
  let wrapper;

  const mockFrecentProjectsResponse = {
    data: {
      frecentProjects: [
        {
          id: 'gid://gitlab/Project/1',
          name: 'GitLab',
          namespace: 'gitlab-org / GitLab',
          fullPath: 'gitlab-org/gitlab',
          avatarUrl: null,
        },
        {
          id: 'gid://gitlab/Project/2',
          name: 'Runner',
          namespace: 'gitlab-org / Runner',
          fullPath: 'gitlab-org/gitlab-runner',
          avatarUrl: 'https://example.com/avatar.png',
        },
      ],
    },
  };

  const frecentProjectsQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(mockFrecentProjectsResponse);
  const frecentProjectsQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const createComponent = ({
    frecentProjectsHandler = frecentProjectsQuerySuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo([[FrecentProjectsQuery, frecentProjectsHandler]]);

    wrapper = shallowMountExtended(ProjectsList, {
      apolloProvider: mockApollo,
    });
  };

  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findErrorMessage = () =>
    wrapper.findByText('Your projects are not available. Please refresh the page to try again.');
  const findEmptyState = () => wrapper.findByText('Projects you visit will appear here.');
  const findProjectsList = () => wrapper.find('ul');
  const findProjectLinks = () => wrapper.findAll('a[href^="/"]');
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
      createComponent({ frecentProjectsHandler: frecentProjectsQueryErrorHandler });
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

  describe('empty state and frequently visited message', () => {
    it('shows empty state when there are no projects', async () => {
      const emptyResponse = {
        data: {
          frecentProjects: [],
        },
      };

      const emptyQueryHandler = jest.fn().mockResolvedValue(emptyResponse);
      createComponent({ frecentProjectsHandler: emptyQueryHandler });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findProjectsList().exists()).toBe(false);
      expect(findFrequentlyVisitedMessage().exists()).toBe(false);
    });

    it('does not show frequently visited message during loading', () => {
      createComponent();

      expect(findFrequentlyVisitedMessage().exists()).toBe(false);
    });

    it('does not show frequently visited message during error state', async () => {
      createComponent({ frecentProjectsHandler: frecentProjectsQueryErrorHandler });
      await waitForPromises();

      expect(findFrequentlyVisitedMessage().exists()).toBe(false);
    });
  });

  describe('GraphQL query', () => {
    it('makes the correct GraphQL query', () => {
      createComponent();

      expect(frecentProjectsQuerySuccessHandler).toHaveBeenCalled();
    });
  });

  describe('projects rendering', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders projects with correct URLs and avatars', () => {
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
});
