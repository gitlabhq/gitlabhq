import { getPageParams } from '~/packages_and_registries/dependency_proxy/utils';

describe('getPageParams', () => {
  it('should return the previous page params if before cursor is available', () => {
    const pageInfo = { before: 'abc123' };
    expect(getPageParams(pageInfo)).toEqual({
      first: null,
      before: pageInfo.before,
      last: 20,
    });
  });

  it('should return the next page params if after cursor is available', () => {
    const pageInfo = { after: 'abc123' };
    expect(getPageParams(pageInfo)).toEqual({
      after: pageInfo.after,
      first: 20,
    });
  });

  it('should return an empty object if both before and after cursors are not available', () => {
    const pageInfo = {};
    expect(getPageParams(pageInfo)).toEqual({});
  });
});
