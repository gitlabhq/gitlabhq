import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import domContentLoaded from '~/feature_highlight/feature_highlight_options';

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

    it('should not call highlightFeatures when breakpoint is not xl', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('lg');

      expect(domContentLoaded()).toBe(false);
    });

    it('should call highlightFeatures when breakpoint is xl', () => {
      jest.spyOn(bp, 'getBreakpointSize').mockReturnValue('xl');

      expect(domContentLoaded()).toBe(true);
    });
  });
});
