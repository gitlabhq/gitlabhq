import {
  getAccessLevels,
  generateRefDestinationPath,
  getAccessLevelInputFromEdges,
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

    it('returns an array with groupId when node has group.id', () => {
      const edges = [{ node: { group: { id: 1 } } }];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ groupId: 1 }]);
    });

    it('returns an array with userId when node has user.id', () => {
      const edges = [{ node: { user: { id: 2 } } }];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ userId: 2 }]);
    });

    it('returns an array with groupId, and userId when node has all properties', () => {
      const edges = [
        {
          node: {
            accessLevel: 30,
            group: { id: 1 },
            user: { id: 2 },
          },
        },
      ];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ groupId: 1, userId: 2 }]);
    });

    it('returns an array with multiple objects when given multiple edges', () => {
      const edges = [
        { node: { accessLevel: 30, group: { id: 1 } } },
        { node: { user: { id: 2 } } },
        { node: { accessLevel: 40 } },
      ];
      const result = getAccessLevelInputFromEdges(edges);

      expect(result).toEqual([{ groupId: 1 }, { userId: 2 }, { accessLevel: 40 }]);
    });
  });
});
