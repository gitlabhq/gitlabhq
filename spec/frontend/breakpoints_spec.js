import bp, { breakpoints } from '~/breakpoints';

describe('breakpoints', () => {
  Object.keys(breakpoints).forEach(key => {
    const size = breakpoints[key];

    it(`returns ${key} when larger than ${size}`, () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(size + 10);

      expect(bp.getBreakpointSize()).toBe(key);
    });
  });

  describe('isDesktop', () => {
    it('returns true when screen size is medium', () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(breakpoints.md + 10);

      expect(bp.isDesktop()).toBe(true);
    });

    it('returns false when screen size is small', () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(breakpoints.sm + 10);

      expect(bp.isDesktop()).toBe(false);
    });
  });
});
