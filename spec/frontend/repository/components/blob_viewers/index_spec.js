import { loadViewer, viewers } from '~/repository/components/blob_viewers';
import { OPENAPI_FILE_TYPE, JSON_LANGUAGE } from '~/repository/constants';

describe('Blob Viewers index', () => {
  describe('loadViewer', () => {
    it('loads the openapi viewer', () => {
      const result = loadViewer(OPENAPI_FILE_TYPE, false, true, JSON_LANGUAGE);
      expect(result).toBe(viewers[OPENAPI_FILE_TYPE]);
    });
  });
});
