import { getAccessLevels } from '~/projects/settings/utils';
import { pushAccessLevelsMockResponse, pushAccessLevelsMockResult } from './mock_data';

describe('Utils', () => {
  describe('getAccessLevels', () => {
    it('takes accessLevels response data and returns acecssLevels object', () => {
      const pushAccessLevels = getAccessLevels(pushAccessLevelsMockResponse);
      expect(pushAccessLevels).toEqual(pushAccessLevelsMockResult);
    });
  });
});
