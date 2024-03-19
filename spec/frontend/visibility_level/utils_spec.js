import { restrictedVisibilityLevelsMessage } from '~/visibility_level/utils';
import {
  VISIBILITY_LEVELS_STRING_TO_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
} from '~/visibility_level/constants';

describe('restrictedVisibilityLevelsMessage', () => {
  describe('when no levels are restricted', () => {
    it('returns empty string', () => {
      expect(
        restrictedVisibilityLevelsMessage({
          availableVisibilityLevels: Object.values(VISIBILITY_LEVELS_STRING_TO_INTEGER),
          restrictedVisibilityLevels: [],
        }),
      ).toBe('');
    });
  });

  describe('when some levels have been restricted', () => {
    it('returns expected message', () => {
      expect(
        restrictedVisibilityLevelsMessage({
          availableVisibilityLevels: [VISIBILITY_LEVEL_PRIVATE_INTEGER],
          restrictedVisibilityLevels: [
            VISIBILITY_LEVEL_INTERNAL_INTEGER,
            VISIBILITY_LEVEL_PUBLIC_INTEGER,
          ],
        }),
      ).toBe('Other visibility settings have been disabled by the administrator.');
    });
  });

  describe('when all visibility levels are restricted', () => {
    it('returns expected message', () => {
      expect(
        restrictedVisibilityLevelsMessage({
          availableVisibilityLevels: [],
          restrictedVisibilityLevels: Object.values(VISIBILITY_LEVELS_STRING_TO_INTEGER),
        }),
      ).toBe('Visibility settings have been disabled by the administrator.');
    });
  });
});
