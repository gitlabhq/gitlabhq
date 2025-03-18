import { scrollBehavior, smoothScrollTo, smoothScrollTop } from '~/behaviors/smooth_scroll';

describe('smooth_scroll', () => {
  let scrollToSpy;

  beforeEach(() => {
    scrollToSpy = jest.spyOn(window, 'scrollTo');
  });

  afterEach(() => {
    scrollToSpy.mockRestore();
  });

  describe('scrollBehavior', () => {
    describe('when user prefers reduced motion', () => {
      beforeEach(() => {
        jest.spyOn(window, 'matchMedia').mockReturnValue({ matches: true });
      });

      it('returns `auto`', () => {
        expect(scrollBehavior()).toBe('auto');
      });
    });

    describe('when user does not prefer reduced motion', () => {
      beforeEach(() => {
        jest.spyOn(window, 'matchMedia').mockReturnValue({ matches: false });
      });

      it('returns `smooth`', () => {
        expect(scrollBehavior()).toBe('smooth');
      });
    });
  });

  describe('smoothScrollTo', () => {
    it('calls scrollTo with the provided options', () => {
      smoothScrollTo({ top: 100 });

      expect(scrollToSpy).toHaveBeenCalledWith({
        top: 100,
        behavior: expect.stringMatching('auto|smooth'),
      });
    });
  });

  describe('smoothScrollTop', () => {
    it('calls scrollTo with top 0', () => {
      smoothScrollTop();

      expect(scrollToSpy).toHaveBeenCalledWith({
        top: 0,
        behavior: expect.stringMatching('auto|smooth'),
      });
    });
  });
});
