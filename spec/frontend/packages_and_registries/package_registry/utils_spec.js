import {
  getPackageTypeLabel,
  getNextPageParams,
  getPreviousPageParams,
  getPageParams,
} from '~/packages_and_registries/package_registry/utils';

describe('Packages shared utils', () => {
  describe('getPackageTypeLabel', () => {
    describe.each`
      packageType   | expectedResult
      ${'CONAN'}    | ${'Conan'}
      ${'MAVEN'}    | ${'Maven'}
      ${'NPM'}      | ${'npm'}
      ${'NUGET'}    | ${'NuGet'}
      ${'PYPI'}     | ${'PyPI'}
      ${'RUBYGEMS'} | ${'RubyGems'}
      ${'COMPOSER'} | ${'Composer'}
      ${'DEBIAN'}   | ${'Debian'}
      ${'HELM'}     | ${'Helm'}
      ${'ML_MODEL'} | ${'MlModel'}
      ${'FOO'}      | ${null}
    `(`package type`, ({ packageType, expectedResult }) => {
      it(`${packageType} should show as ${expectedResult}`, () => {
        expect(getPackageTypeLabel(packageType)).toBe(expectedResult);
      });
    });
  });
});

describe('getNextPageParams', () => {
  it('should return the next page params with the provided cursor', () => {
    const cursor = 'abc123';
    expect(getNextPageParams(cursor)).toEqual({
      after: cursor,
      first: 20,
    });
  });
});

describe('getPreviousPageParams', () => {
  it('should return the previous page params with the provided cursor', () => {
    const cursor = 'abc123';
    expect(getPreviousPageParams(cursor)).toEqual({
      first: null,
      before: cursor,
      last: 20,
    });
  });
});

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
