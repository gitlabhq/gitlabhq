import {
  getAccessLevels,
  generateRefDestinationPath,
  getAccessLevelInputFromEdges,
  getAccessLevelsRolesText,
  getAccessLevelsDeployKeysText,
} from '~/projects/settings/utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { accessLevelsMockResponse, accessLevelsMockResult } from './mock_data';

describe('Utils', () => {
  describe('getAccessLevels', () => {
    it('takes accessLevels response data and returns accessLevels object', () => {
      const pushAccessLevels = getAccessLevels(accessLevelsMockResponse);
      expect(pushAccessLevels).toEqual(accessLevelsMockResult);
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

  describe('getAccessLevelInputFromEdges', () => {
    it('returns an empty array when given an empty array', () => {
      const edges = [];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([]);
    });

    it('returns an array with accessLevel when node has accessLevel', () => {
      const edges = [{ node: { accessLevel: 30 } }];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ accessLevel: 30 }]);
    });

    it('returns an array with deployKeys when node has deployKeys', () => {
      const edges = [{ node: { deployKey: { id: 14 } } }];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ deployKeyId: 14 }]);
    });

    it('returns an array with multiple objects when given multiple edges', () => {
      const edges = [{ node: { deployKey: { id: 14 } } }, { node: { accessLevel: 40 } }];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ deployKeyId: 14 }, { accessLevel: 40 }]);
    });
  });

  describe('getAccessLevelsRolesText', () => {
    it('returns an empty array when no roles', () => {
      const result = getAccessLevelsRolesText({ roles: [] });
      expect(result).toEqual([]);
    });

    it('returns an empty array when roles is undefined', () => {
      const result = getAccessLevelsRolesText({});
      expect(result).toEqual([]);
    });

    it('returns roles text for a single role', () => {
      const result = getAccessLevelsRolesText({ roles: [40] });
      expect(result).toEqual(['Maintainers']);
    });

    it('returns roles text for multiple roles', () => {
      const result = getAccessLevelsRolesText({ roles: [30, 40] });
      expect(result).toEqual(['Developers and Maintainers, Maintainers']);
    });
  });

  describe('getAccessLevelsDeployKeysText', () => {
    it('returns an empty array when no deploy keys', () => {
      const result = getAccessLevelsDeployKeysText({ deployKeys: [] });
      expect(result).toEqual([]);
    });

    it('returns an empty array when deployKeys is undefined', () => {
      const result = getAccessLevelsDeployKeysText({});
      expect(result).toEqual([]);
    });

    it('returns deploy keys text for a single deploy key', () => {
      const result = getAccessLevelsDeployKeysText({ deployKeys: [{ id: '1' }] });
      expect(result).toEqual(['1 deploy key']);
    });

    it('returns deploy keys text for multiple deploy keys', () => {
      const result = getAccessLevelsDeployKeysText({ deployKeys: [{ id: '1' }, { id: '2' }] });
      expect(result).toEqual(['2 deploy keys']);
    });
  });
});
