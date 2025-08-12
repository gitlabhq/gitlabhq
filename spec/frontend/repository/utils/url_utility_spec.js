import { generateHistoryUrl, encodeRepositoryPath } from '~/repository/utils/url_utility';

describe('Repository URL utilities', () => {
  describe('encodeRepositoryPath', () => {
    it('returns empty string for empty input', () => {
      expect(encodeRepositoryPath('')).toBe('');
      expect(encodeRepositoryPath(null)).toBe('');
      expect(encodeRepositoryPath(undefined)).toBe('');
    });

    it('preserves forward slashes', () => {
      expect(encodeRepositoryPath('path/to/file')).toBe('path/to/file');
      expect(encodeRepositoryPath('/absolute/path/')).toBe('/absolute/path/');
    });

    it('encodes spaces', () => {
      expect(encodeRepositoryPath('path with spaces')).toBe('path%20with%20spaces');
      expect(encodeRepositoryPath('file name.txt')).toBe('file%20name.txt');
    });

    it('encodes hash characters', () => {
      expect(encodeRepositoryPath('directory#with#hash')).toBe('directory%23with%23hash');
      expect(encodeRepositoryPath('path/to/#special#/file')).toBe('path/to/%23special%23/file');
    });

    it('preserves commonly used characters that should not be encoded', () => {
      expect(encodeRepositoryPath('path-with_underscores.and.dots')).toBe(
        'path-with_underscores.and.dots',
      );
      expect(encodeRepositoryPath('file(1).txt')).toBe('file(1).txt');
    });

    it('handles mixed special characters correctly', () => {
      expect(encodeRepositoryPath('path/with spaces/#hash/and$dollar')).toBe(
        'path/with%20spaces/%23hash/and$dollar',
      );
      expect(encodeRepositoryPath('complex#path with@symbols')).toBe(
        'complex%23path%20with@symbols',
      );
    });

    it('handles multiple hash characters', () => {
      expect(encodeRepositoryPath('##multiple##hashes##')).toBe('%23%23multiple%23%23hashes%23%23');
    });

    it('handles edge cases with special character combinations', () => {
      expect(encodeRepositoryPath('#')).toBe('%23');
      expect(encodeRepositoryPath('/#/')).toBe('/%23/');
      expect(encodeRepositoryPath('path/#')).toBe('path/%23');
      expect(encodeRepositoryPath('#/path')).toBe('%23/path');
    });

    it('works consistently with encodeURI for non-hash characters', () => {
      const testPaths = ['simple/path', 'path with spaces', 'file$name', 'path(1)/file[2].txt'];

      testPaths.forEach((path) => {
        const ourResult = encodeRepositoryPath(path);
        const encodeURIResult = encodeURI(path);

        // Our function should match encodeURI for paths without hash
        expect(ourResult).toBe(encodeURIResult);
      });
    });

    it('differs from encodeURI only for hash characters', () => {
      const pathWithHash = 'path/with#hash';

      expect(encodeRepositoryPath(pathWithHash)).toBe('path/with%23hash');
      expect(encodeURI(pathWithHash)).toBe('path/with#hash');
    });
  });

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
