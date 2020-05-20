import fileResolver from '~/static_site_editor/graphql/resolvers/file';
import loadSourceContent from '~/static_site_editor/services/load_source_content';

import {
  projectId,
  sourcePath,
  sourceContentTitle as title,
  sourceContent as content,
} from '../../mock_data';

jest.mock('~/static_site_editor/services/load_source_content', () => jest.fn());

describe('static_site_editor/graphql/resolvers/file', () => {
  it('returns file content and title when fetching file successfully', () => {
    loadSourceContent.mockResolvedValueOnce({ title, content });

    return fileResolver({ fullPath: projectId }, { path: sourcePath }).then(file => {
      expect(file).toEqual({
        __typename: 'File',
        title,
        content,
      });
    });
  });
});
