import { removeLinkedFileUrlParams } from '~/rapid_diffs/utils/linked_file';

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

  it('preserves non-line hashes', () => {
    const url = new URL('https://example.com/project/merge_requests/1#some-anchor');
    const result = removeLinkedFileUrlParams(url);
    expect(result.hash).toBe('#some-anchor');
  });
});
