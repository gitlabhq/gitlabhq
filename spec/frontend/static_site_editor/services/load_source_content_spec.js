import Api from '~/api';

import loadSourceContent from '~/static_site_editor/services/load_source_content';

import {
  sourceContentYAML as sourceContent,
  sourceContentTitle,
  projectId,
  sourcePath,
} from '../mock_data';

describe('loadSourceContent', () => {
  describe('requesting source content succeeds', () => {
    let result;

    beforeEach(() => {
      jest.spyOn(Api, 'getRawFile').mockResolvedValue({ data: sourceContent });

      return loadSourceContent({ projectId, sourcePath }).then((_result) => {
        result = _result;
      });
    });

    it('calls getRawFile API with project id and source path', () => {
      expect(Api.getRawFile).toHaveBeenCalledWith(projectId, sourcePath);
    });

    it('extracts page title from source content', () => {
      expect(result.title).toBe(sourceContentTitle);
    });

    it('returns raw content', () => {
      expect(result.content).toBe(sourceContent);
    });
  });
});
