import { buildSortedUrl } from '~/credentials/utils';

describe('buildSortedUrl', () => {
  it('builds correct URL for ascending sort', () => {
    expect(buildSortedUrl('name', false)).toBe('http://test.host/?sort=name_desc');
  });

  it('builds correct URL for descending sort', () => {
    expect(buildSortedUrl('created', true)).toBe('http://test.host/?sort=created_asc');
  });
});
