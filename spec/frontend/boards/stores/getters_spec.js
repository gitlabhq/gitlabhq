import getters from '~/boards/stores/getters';

describe('Boards - Getters', () => {
  describe('getLabelToggleState', () => {
    it('should return "on" when isShowingLabels is true', () => {
      const state = {
        isShowingLabels: true,
      };

      expect(getters.getLabelToggleState(state)).toBe('on');
    });

    it('should return "off" when isShowingLabels is false', () => {
      const state = {
        isShowingLabels: false,
      };

      expect(getters.getLabelToggleState(state)).toBe('off');
    });
  });
});
