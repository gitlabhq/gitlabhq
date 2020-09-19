import savedContentMetaQuery from '~/static_site_editor/graphql/queries/saved_content_meta.query.graphql';
import submitContentChanges from '~/static_site_editor/services/submit_content_changes';
import submitContentChangesResolver from '~/static_site_editor/graphql/resolvers/submit_content_changes';

import {
  projectId as project,
  sourcePath,
  username,
  sourceContentYAML as content,
  savedContentMeta,
} from '../../mock_data';

jest.mock('~/static_site_editor/services/submit_content_changes', () => jest.fn());

describe('static_site_editor/graphql/resolvers/submit_content_changes', () => {
  it('writes savedContentMeta query with the data returned by the submitContentChanges service', () => {
    const cache = { writeQuery: jest.fn() };

    submitContentChanges.mockResolvedValueOnce(savedContentMeta);

    return submitContentChangesResolver(
      {},
      { input: { path: sourcePath, project, sourcePath, content, username } },
      { cache },
    ).then(() => {
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: savedContentMetaQuery,
        data: {
          savedContentMeta: {
            __typename: 'SavedContentMeta',
            ...savedContentMeta,
          },
        },
      });
    });
  });
});
