import { DEFAULT_TH_CLASSES } from '~/lib/utils/constants';
import * as tableUtils from '~/lib/utils/table_utility';

describe('table_utility', () => {
  describe('thWidthClass', () => {
    it('returns the width class including default table header classes', () => {
      const width = 50;
      expect(tableUtils.thWidthClass(width)).toBe(`gl-w-${width}p ${DEFAULT_TH_CLASSES}`);
    });
  });
});
