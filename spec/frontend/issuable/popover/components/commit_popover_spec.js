import { GlAvatar, GlPopover, GlSkeletonLoader, GlTruncate } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommitPopover from '~/issuable/popover/components/commit_popover.vue';
import commitQuery from '~/issuable/popover/queries/commit.query.graphql';

Vue.use(VueApollo);

const mockCommit = {
  id: 'gid://gitlab/Commit/abc123',
  title: 'Fix bug in feature',
  shortId: 'abc123de',
  authoredDate: '2024-01-15T10:00:00Z',
  authorName: 'Test Author',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Test Author',
    avatarUrl: 'https://example.com/avatar.png',
  },
  webPath: '/gitlab-org/gitlab-test/-/commit/abc123de',
};

const mockQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      repository: {
        commit: mockCommit,
      },
    },
  },
};

const mockNullResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      repository: {
        commit: null,
      },
    },
  },
};

describe('CommitPopover', () => {
  let wrapper;

  const createComponent = ({
    queryResponse = jest.fn().mockResolvedValue(mockQueryResponse),
  } = {}) => {
    wrapper = shallowMountExtended(CommitPopover, {
      apolloProvider: createMockApollo([[commitQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        commitSha: 'abc123de',
        projectPath: 'gitlab-org/gitlab-test',
      },
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findCommitLink = () => wrapper.findByTestId('commit-title-link');
  const findTruncate = () => wrapper.findComponent(GlTruncate);
  const findSha = () => wrapper.findByTestId('commit-sha-link');
  const findAuthor = () => wrapper.findByTestId('commit-author-name');
  const findErrorMessage = () => wrapper.findByTestId('commit-error-message');

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render commit content', () => {
      expect(findCommitLink().exists()).toBe(false);
    });

    it('does not render the error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('passes commitSha and projectPath as query variables', () => {
      const queryHandler = jest.fn().mockResolvedValue(mockQueryResponse);
      createComponent({ queryResponse: queryHandler });

      expect(queryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sha: 'abc123de',
          projectPath: 'gitlab-org/gitlab-test',
        }),
      );
    });
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('renders the commit title', () => {
      expect(findTruncate().props('text')).toBe(mockCommit.title);
    });

    it('renders the author name', () => {
      expect(findAuthor().text()).toBe(mockCommit.author.name);
    });

    it('renders the author avatar', () => {
      expect(findAvatar().props('src')).toBe(mockCommit.author.avatarUrl);
    });

    it('renders the short SHA', () => {
      expect(findSha().text()).toBe(mockCommit.shortId);
    });
  });

  describe('when commit is not found (null response)', () => {
    beforeEach(async () => {
      createComponent({ queryResponse: jest.fn().mockResolvedValue(mockNullResponse) });
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render commit content', () => {
      expect(findCommitLink().exists()).toBe(false);
    });

    it('does not render the error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('hides the popover', () => {
      expect(findPopover().props('show')).toBe(false);
    });
  });

  describe('when the query errors', () => {
    beforeEach(async () => {
      createComponent({ queryResponse: jest.fn().mockRejectedValue(new Error('Network error')) });
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render commit content', () => {
      expect(findCommitLink().exists()).toBe(false);
    });

    it('shows the popover', () => {
      expect(findPopover().props('show')).toBe(true);
    });

    it('renders a user-friendly error message', () => {
      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe('Could not load commit. Please reload the page.');
    });
  });
});
