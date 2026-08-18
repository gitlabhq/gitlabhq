import { resolveInheritedWidgetsDraft } from '~/work_items/board/filter_inheritance';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import searchMilestonesQuery from '~/work_items/board/graphql/search_milestones.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('board filter inheritance', () => {
  const fullPath = 'group/project';

  const bug = {
    __typename: 'Label',
    id: 'gid://gitlab/Label/1',
    title: 'bug',
    description: 'Defect',
    color: '#ff0000',
    textColor: '#ffffff',
  };
  const frontend = {
    __typename: 'Label',
    id: 'gid://gitlab/Label/2',
    title: 'frontend',
    description: null,
    color: '#00ff00',
    textColor: '#000000',
  };

  const labelsResponse = (nodes, { isGroup = false } = {}) => ({
    data: isGroup
      ? { group: { id: 'gid://gitlab/Group/1', labels: { nodes } } }
      : { project: { id: 'gid://gitlab/Project/1', labels: { nodes } } },
  });

  const createClient = (queryImpl = () => Promise.resolve(labelsResponse([]))) => ({
    query: jest.fn(queryImpl),
  });

  describe('labels', () => {
    it('returns an empty draft and runs no query when no label filter is active', async () => {
      const apolloClient = createClient();

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: {},
      });

      expect(result).toEqual({});
      expect(apolloClient.query).not.toHaveBeenCalled();
    });

    it('handles a single label filter passed as a string', async () => {
      const apolloClient = createClient(() => Promise.resolve(labelsResponse([bug])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { labelName: 'bug' },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchLabelsQuery,
        variables: { fullPath, isProject: true, search: 'bug' },
      });
      expect(result).toEqual({ LABELS: { labels: { nodes: [bug] } } });
    });

    it('resolves the filtered label titles into a labels widget in the create flow', async () => {
      const apolloClient = createClient(({ variables }) =>
        Promise.resolve(labelsResponse(variables.search === 'bug' ? [bug] : [frontend])),
      );

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { labelName: ['bug', 'frontend'] },
      });

      expect(result).toEqual({ LABELS: { labels: { nodes: [bug, frontend] } } });
    });

    it('queries project labels for a project board', async () => {
      const apolloClient = createClient(() => Promise.resolve(labelsResponse([bug])));

      await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { labelName: ['bug'] },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchLabelsQuery,
        variables: { fullPath, isProject: true, search: 'bug' },
      });
    });

    it('queries group labels for a group board', async () => {
      const apolloClient = createClient(() =>
        Promise.resolve(labelsResponse([bug], { isGroup: true })),
      );

      await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: true,
        filters: { labelName: ['bug'] },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchLabelsQuery,
        variables: { fullPath, isProject: false, search: 'bug' },
      });
    });

    it('captures the error and yields an empty draft when the query fails', async () => {
      const error = new Error('error');
      const apolloClient = createClient(() => Promise.reject(error));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { labelName: ['bug'] },
      });

      expect(result).toEqual({});
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('assignees', () => {
    const root = {
      __typename: 'User',
      id: 'gid://gitlab/User/1',
      username: 'root',
      name: 'Administrator',
      avatarUrl: '/root.png',
      webUrl: '/root',
      webPath: '/root',
    };
    const alice = {
      __typename: 'User',
      id: 'gid://gitlab/User/2',
      username: 'alice',
      name: 'Alice',
      avatarUrl: '/alice.png',
      webUrl: '/alice',
      webPath: '/alice',
    };

    const usersResponse = (nodes, { isGroup = false } = {}) => ({
      data: isGroup ? { groupNamespace: { users: nodes } } : { namespace: { users: nodes } },
    });

    it('returns an empty draft and runs no query when no assignee filter is active', async () => {
      const apolloClient = createClient();

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: {},
      });

      expect(result).toEqual({});
      expect(apolloClient.query).not.toHaveBeenCalled();
    });

    it('handles a single assignee filter passed as a string', async () => {
      const apolloClient = createClient(() => Promise.resolve(usersResponse([root])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { assigneeUsernames: 'root' },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: usersSearchQuery,
        variables: { fullPath, isProject: true, search: 'root' },
      });
      expect(result).toEqual({ ASSIGNEES: { assignees: { nodes: [root] } } });
    });

    it('resolves the filtered usernames into an assignees widget in the create flow', async () => {
      const apolloClient = createClient(({ variables }) =>
        Promise.resolve(usersResponse(variables.search === 'root' ? [root] : [alice])),
      );

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { assigneeUsernames: ['root', 'alice'] },
      });

      expect(result).toEqual({ ASSIGNEES: { assignees: { nodes: [root, alice] } } });
    });

    it('reads group users for a group board', async () => {
      const apolloClient = createClient(() =>
        Promise.resolve(usersResponse([root], { isGroup: true })),
      );

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: true,
        filters: { assigneeUsernames: ['root'] },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: usersSearchQuery,
        variables: { fullPath, isProject: false, search: 'root' },
      });
      expect(result).toEqual({ ASSIGNEES: { assignees: { nodes: [root] } } });
    });

    it('ignores search results whose username does not match the filter', async () => {
      const apolloClient = createClient(() => Promise.resolve(usersResponse([alice])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { assigneeUsernames: ['root'] },
      });

      expect(result).toEqual({});
    });

    it('captures the error and yields an empty draft when the query fails', async () => {
      const error = new Error('error');
      const apolloClient = createClient(() => Promise.reject(error));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { assigneeUsernames: ['root'] },
      });

      expect(result).toEqual({});
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('milestone', () => {
    const sprint = {
      __typename: 'Milestone',
      id: 'gid://gitlab/Milestone/1',
      title: 'Sprint 1',
      state: 'active',
      expired: false,
      startDate: '2026-01-01',
      dueDate: '2026-01-14',
      webPath: '/sprint-1',
      projectMilestone: true,
    };

    const milestonesResponse = (nodes, { isGroup = false } = {}) => ({
      data: isGroup
        ? { group: { id: 'gid://gitlab/Group/1', milestones: { nodes } } }
        : { project: { id: 'gid://gitlab/Project/1', milestones: { nodes } } },
    });

    it('returns an empty draft and runs no query when no milestone filter is active', async () => {
      const apolloClient = createClient();

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: {},
      });

      expect(result).toEqual({});
      expect(apolloClient.query).not.toHaveBeenCalled();
    });

    it('resolves a single milestone filter into a milestone widget in the create flow', async () => {
      const apolloClient = createClient(() => Promise.resolve(milestonesResponse([sprint])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { milestoneTitle: 'Sprint 1' },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchMilestonesQuery,
        variables: { fullPath, isProject: true, search: 'Sprint 1' },
      });
      expect(result).toEqual({ MILESTONE: { milestone: sprint } });
    });

    it('inherits only the first milestone title when several are filtered', async () => {
      const apolloClient = createClient(() => Promise.resolve(milestonesResponse([sprint])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { milestoneTitle: ['Sprint 1', 'Sprint 2'] },
      });

      expect(apolloClient.query).toHaveBeenCalledTimes(1);
      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchMilestonesQuery,
        variables: { fullPath, isProject: true, search: 'Sprint 1' },
      });
      expect(result).toEqual({ MILESTONE: { milestone: sprint } });
    });

    it('reads group milestones for a group board', async () => {
      const apolloClient = createClient(() =>
        Promise.resolve(milestonesResponse([sprint], { isGroup: true })),
      );

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: true,
        filters: { milestoneTitle: 'Sprint 1' },
      });

      expect(apolloClient.query).toHaveBeenCalledWith({
        query: searchMilestonesQuery,
        variables: { fullPath, isProject: false, search: 'Sprint 1' },
      });
      expect(result).toEqual({ MILESTONE: { milestone: sprint } });
    });

    it('ignores search results whose title does not match the filter', async () => {
      const apolloClient = createClient(() => Promise.resolve(milestonesResponse([sprint])));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { milestoneTitle: 'Backlog' },
      });

      expect(result).toEqual({});
    });

    it('captures the error and yields an empty draft when the query fails', async () => {
      const error = new Error('error');
      const apolloClient = createClient(() => Promise.reject(error));

      const result = await resolveInheritedWidgetsDraft({
        apolloClient,
        fullPath,
        isGroup: false,
        filters: { milestoneTitle: 'Sprint 1' },
      });

      expect(result).toEqual({});
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
