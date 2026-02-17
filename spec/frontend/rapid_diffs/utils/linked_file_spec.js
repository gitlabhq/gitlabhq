import {
  removeLinkedFileUrlParams,
  withLinkedFileUrlParams,
} from '~/rapid_diffs/utils/linked_file';

describe('linked_file utilities', () => {
  describe('removeLinkedFileUrlParams', () => {
    it('removes all file parameters at once', () => {
      const url = new URL(
        'https://example.com/project/merge_requests/1?file_path=test.txt&old_path=old.txt&new_path=new.txt&other=value',
      );
      const result = removeLinkedFileUrlParams(url);
      expect(result.searchParams.has('file_path')).toBe(false);
      expect(result.searchParams.has('old_path')).toBe(false);
      expect(result.searchParams.has('new_path')).toBe(false);
      expect(result.searchParams.get('other')).toBe('value');
    });

    it('removes line hash', () => {
      const url = new URL('https://example.com/project/merge_requests/1#line_123');
      const result = removeLinkedFileUrlParams(url);
      expect(result.hash).toBe('');
    });

    it('removes file hash', () => {
      const url = new URL(
        'https://example.com/project/merge_requests/1#abcdefabcdef1234567890123456789012345678',
      );
      const result = removeLinkedFileUrlParams(url);
      expect(result.hash).toBe('');
    });

    it('preserves non-line hashes', () => {
      const url = new URL('https://example.com/project/merge_requests/1#some-anchor');
      const result = removeLinkedFileUrlParams(url);
      expect(result.hash).toBe('#some-anchor');
    });
  });

  describe('withLinkedFileUrlParams', () => {
    it('sets file_path when oldPath equals newPath', () => {
      const url = new URL('https://example.com/merge_requests/1');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
      });

      expect(result.searchParams.get('file_path')).toBe('app/models/user.rb');
      expect(result.searchParams.has('old_path')).toBe(false);
      expect(result.searchParams.has('new_path')).toBe(false);
    });

    it('sets old_path and new_path when paths differ', () => {
      const url = new URL('https://example.com/merge_requests/1');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/old_user.rb',
        newPath: 'app/models/new_user.rb',
      });

      expect(result.searchParams.get('old_path')).toBe('app/models/old_user.rb');
      expect(result.searchParams.get('new_path')).toBe('app/models/new_user.rb');
      expect(result.searchParams.has('file_path')).toBe(false);
    });

    it('removes existing linked file parameters before adding new ones', () => {
      const url = new URL(
        'https://example.com/merge_requests/1?file_path=old_file.rb&old_path=old.rb&new_path=new.rb',
      );
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
      });

      expect(result.searchParams.get('file_path')).toBe('app/models/user.rb');
      expect(result.searchParams.has('old_path')).toBe(false);
      expect(result.searchParams.has('new_path')).toBe(false);
    });

    it('preserves other search parameters', () => {
      const url = new URL('https://example.com/merge_requests/1?view=parallel&diff_id=123');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
      });

      expect(result.searchParams.get('view')).toBe('parallel');
      expect(result.searchParams.get('diff_id')).toBe('123');
      expect(result.searchParams.get('file_path')).toBe('app/models/user.rb');
    });

    it('removes #line_ hash from original URL', () => {
      const url = new URL('https://example.com/merge_requests/1#line_123');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
      });

      expect(result.hash).toBe('');
      expect(result.searchParams.get('file_path')).toBe('app/models/user.rb');
    });

    it('sets hash when fileId is provided', () => {
      const url = new URL('https://example.com/merge_requests/1');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
        fileId: 'abc123',
      });

      expect(result.hash).toBe('#abc123');
      expect(result.searchParams.get('file_path')).toBe('app/models/user.rb');
    });

    it('preserves hash when fileId is not provided', () => {
      const url = new URL('https://example.com/merge_requests/1#other');
      const result = withLinkedFileUrlParams(url, {
        oldPath: 'app/models/user.rb',
        newPath: 'app/models/user.rb',
      });

      expect(result.hash).toBe('#other');
    });
  });
});
