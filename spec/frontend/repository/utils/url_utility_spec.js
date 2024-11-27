import { generateHistoryUrl } from '~/repository/utils/url_utility';

describe('Repository URL utilities', () => {
  describe('generateHistoryUrl', () => {
    it('generates correct URL with path and ref type', () => {
      const historyLink = '/-/commits';
      const path = 'path/to/file.js';
      const refType = 'branch';

      const result = generateHistoryUrl(historyLink, path, refType);

      expect(result.pathname).toBe('/-/commits/path/to/file.js');
      expect(result.searchParams.get('ref_type')).toBe('branch');
    });

    it('generates correct URL when path is empty', () => {
      const historyLink = '/-/commits';
      const path = '';
      const refType = 'tag';

      const result = generateHistoryUrl(historyLink, path, refType);

      expect(result.pathname).toBe('/-/commits');
      expect(result.searchParams.get('ref_type')).toBe('tag');
    });

    it('escapes special characters in path', () => {
      const historyLink = '/-/commits';
      const path = 'path/to/file with spaces.js';
      const refType = 'branch';

      const result = generateHistoryUrl(historyLink, path, refType);

      expect(result.pathname).toBe('/-/commits/path/to/file%20with%20spaces.js');
      expect(result.searchParams.get('ref_type')).toBe('branch');
    });

    it('skips refType when is undefined', () => {
      const historyLink = '/-/commits';
      const path = 'path/to/file.js';
      const refType = undefined;

      const result = generateHistoryUrl(historyLink, path, refType);

      expect(result.pathname).toBe('/-/commits/path/to/file.js');
      expect(result.searchParams.get('ref_type')).toBe(null);
    });

    it('does not assign refType twice if it is already present', () => {
      const historyLink = '/-/commits?ref_type=branch';
      const path = 'path/to/file.js';
      const refType = 'branch';

      const result = generateHistoryUrl(historyLink, path, refType);

      expect(result.pathname).toBe('/-/commits/path/to/file.js');
      expect(result.searchParams.get('ref_type')).toBe('branch');
    });
  });
});
