import { PackageType, TrackingCategories } from '~/packages/shared/constants';
import {
  packageTypeToTrackCategory,
  beautifyPath,
  getPackageTypeLabel,
  getCommitLink,
} from '~/packages/shared/utils';
import { packageList } from '../mock_data';

describe('Packages shared utils', () => {
  describe('packageTypeToTrackCategory', () => {
    it('prepend UI to package category', () => {
      expect(packageTypeToTrackCategory()).toMatchInlineSnapshot(`"UI::undefined"`);
    });

    it.each(Object.keys(PackageType))('returns a correct category string for %s', (packageKey) => {
      const packageName = PackageType[packageKey];
      expect(packageTypeToTrackCategory(packageName)).toBe(
        `UI::${TrackingCategories[packageName]}`,
      );
    });
  });

  describe('beautifyPath', () => {
    it('returns a string with spaces around /', () => {
      expect(beautifyPath('foo/bar')).toBe('foo / bar');
    });
    it('does not fail for empty string', () => {
      expect(beautifyPath()).toBe('');
    });
  });

  describe('getPackageTypeLabel', () => {
    describe.each`
      packageType   | expectedResult
      ${'conan'}    | ${'Conan'}
      ${'maven'}    | ${'Maven'}
      ${'npm'}      | ${'npm'}
      ${'nuget'}    | ${'NuGet'}
      ${'pypi'}     | ${'PyPI'}
      ${'rubygems'} | ${'RubyGems'}
      ${'composer'} | ${'Composer'}
      ${'debian'}   | ${'Debian'}
      ${'helm'}     | ${'Helm'}
      ${'foo'}      | ${null}
    `(`package type`, ({ packageType, expectedResult }) => {
      it(`${packageType} should show as ${expectedResult}`, () => {
        expect(getPackageTypeLabel(packageType)).toBe(expectedResult);
      });
    });
  });

  describe('getCommitLink', () => {
    it('returns a relative link when isGroup is false', () => {
      const link = getCommitLink(packageList[0], false);

      expect(link).toContain('../commit');
    });

    describe('when isGroup is true', () => {
      it('returns an absolute link matching project path', () => {
        const mavenPackage = packageList[0];
        const link = getCommitLink(mavenPackage, true);

        expect(link).toContain(`/${mavenPackage.project_path}/commit`);
      });
    });
  });
});
