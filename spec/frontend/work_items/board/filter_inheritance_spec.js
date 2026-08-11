import { resolveInheritedWidgetsDraft } from '~/work_items/board/filter_inheritance';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
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

    it('resolves the filtered label titles into a labels widgets-draft fragment', async () => {
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
});
