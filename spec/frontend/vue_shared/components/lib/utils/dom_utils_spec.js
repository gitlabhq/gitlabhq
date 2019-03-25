import * as domUtils from '~/vue_shared/components/lib/utils/dom_utils';

describe('domUtils', () => {
  describe('pixeliseValue', () => {
    it('should add px to a given Number', () => {
      expect(domUtils.pixeliseValue(12)).toEqual('12px');
    });

    it('should not add px to 0', () => {
      expect(domUtils.pixeliseValue(0)).toEqual('');
    });
  });
});
