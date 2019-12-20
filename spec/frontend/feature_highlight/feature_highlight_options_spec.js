import domContentLoaded from '~/feature_highlight/feature_highlight_options';
import bp from '~/breakpoints';

describe('feature highlight options', () => {
  describe('domContentLoaded', () => {
    it('should not call highlightFeatures when breakpoint is xs', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xs');

      expect(domContentLoaded()).toBe(false);
    });

    it('should not call highlightFeatures when breakpoint is sm', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('sm');

      expect(domContentLoaded()).toBe(false);
    });

    it('should not call highlightFeatures when breakpoint is md', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('md');

      expect(domContentLoaded()).toBe(false);
    });

    it('should call highlightFeatures when breakpoint is lg', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('lg');

      expect(domContentLoaded()).toBe(true);
    });
  });
});
