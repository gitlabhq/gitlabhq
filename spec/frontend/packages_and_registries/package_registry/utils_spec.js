import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';

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
      ${'FOO'}      | ${null}
    `(`package type`, ({ packageType, expectedResult }) => {
      it(`${packageType} should show as ${expectedResult}`, () => {
        expect(getPackageTypeLabel(packageType)).toBe(expectedResult);
      });
    });
  });
});
