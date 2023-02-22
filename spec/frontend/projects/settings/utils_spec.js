import { getAccessLevels, generateRefDestinationPath } from '~/projects/settings/utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { pushAccessLevelsMockResponse, pushAccessLevelsMockResult } from './mock_data';

describe('Utils', () => {
  describe('getAccessLevels', () => {
    it('takes accessLevels response data and returns acecssLevels object', () => {
      const pushAccessLevels = getAccessLevels(pushAccessLevelsMockResponse);
      expect(pushAccessLevels).toEqual(pushAccessLevelsMockResult);
    });
  });

  describe('generateRefDestinationPath', () => {
    const projectRootPath = 'http://test.host/root/Project1';
    const settingsCi = '-/settings/ci_cd';

    it.each`
      currentPath                           | selectedRef             | result
      ${`${projectRootPath}`}               | ${undefined}            | ${`${projectRootPath}`}
      ${`${projectRootPath}`}               | ${'test'}               | ${`${projectRootPath}`}
      ${`${projectRootPath}/${settingsCi}`} | ${'test'}               | ${`${projectRootPath}/${settingsCi}?ref=test`}
      ${`${projectRootPath}/${settingsCi}`} | ${'branch-hyphen'}      | ${`${projectRootPath}/${settingsCi}?ref=branch-hyphen`}
      ${`${projectRootPath}/${settingsCi}`} | ${'test/branch'}        | ${`${projectRootPath}/${settingsCi}?ref=test%2Fbranch`}
      ${`${projectRootPath}/${settingsCi}`} | ${'test/branch-hyphen'} | ${`${projectRootPath}/${settingsCi}?ref=test%2Fbranch-hyphen`}
    `(
      'generates the correct destination path for the `$selectedRef` ref and current url $currentPath by outputting $result',
      ({ currentPath, selectedRef, result }) => {
        setWindowLocation(currentPath);
        expect(generateRefDestinationPath(selectedRef)).toBe(result);
      },
    );
  });
});
