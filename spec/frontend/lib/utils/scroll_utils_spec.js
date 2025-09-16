import {
  isScrolledToBottom,
  isScrolledToTop,
  scrollDown,
  scrollUp,
} from '~/lib/utils/scroll_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('scroll utils', () => {
  let windowScrollTo;
  let elementScrollTo;

  const setUpScrollEnvironment = ({ ...getters }) => {
    Object.defineProperty(global.window, 'scrollTo', { value: windowScrollTo });
    Object.defineProperty(Element.prototype, 'scrollTo', { value: elementScrollTo });

    Object.entries(getters).forEach(([name, value]) => {
      jest.spyOn(Element.prototype, name, 'get').mockReturnValue(value);
    });
  };

  const setUpContainer = () => {
    setHTMLFixture('<div class="js-static-panel-inner">');
  };

  beforeEach(() => {
    windowScrollTo = jest.fn();
    elementScrollTo = jest.fn();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each`
    case                                    | useContainer
    ${'with window as scrolling container'} | ${true}
    ${'with panel as scrolling container'}  | ${false}
  `('$case', ({ useContainer }) => {
    beforeEach(() => {
      if (useContainer) {
        setUpContainer();
      }
    });

    describe('isScrolledToBottom', () => {
      it.each`
        context                                                           | scrollTop | scrollHeight | result
        ${'returns false when not scrolled to bottom'}                    | ${0}      | ${2000}      | ${false}
        ${'returns true when scrolled to bottom'}                         | ${1000}   | ${2000}      | ${true}
        ${'returns true when scrolled to bottom with subpixel precision'} | ${999.25} | ${2000}      | ${true}
        ${'returns true when cannot scroll'}                              | ${0}      | ${500}       | ${true}
      `('$context', ({ scrollTop, scrollHeight, result }) => {
        setUpScrollEnvironment({ scrollTop, clientHeight: 1000, scrollHeight });

        expect(isScrolledToBottom()).toBe(result);
      });
    });

    describe('isScrolledToTop', () => {
      it.each`
        context                                    | scrollTop | scrollHeight | result
        ${'returns true when scrolled to top'}     | ${0}      | ${2000}      | ${true}
        ${'returns true when not scrolled to top'} | ${1000}   | ${2000}      | ${false}
      `('$context', ({ scrollTop, scrollHeight, result }) => {
        setUpScrollEnvironment({ scrollTop, clientHeight: 1000, scrollHeight });

        expect(isScrolledToTop()).toBe(result);
      });
    });
  });

  describe('scrollDown', () => {
    it('scrolls container to top', () => {
      setUpContainer();
      setUpScrollEnvironment({ scrollHeight: 2000 });

      scrollDown();

      expect(elementScrollTo).toHaveBeenCalledWith({ top: 2000 });
    });

    it('scrolls window to top', () => {
      setUpScrollEnvironment({ scrollHeight: 2000 });

      scrollDown();

      expect(windowScrollTo).toHaveBeenCalledWith({ top: 2000 });
    });
  });

  describe('scrollUp', () => {
    it('scrolls container to top', () => {
      setUpContainer();
      setUpScrollEnvironment({ scrollHeight: 2000 });

      scrollUp();

      expect(elementScrollTo).toHaveBeenCalledWith({ top: 0 });
    });

    it('scrolls window to top', () => {
      setUpScrollEnvironment({ scrollHeight: 2000 });

      scrollUp();

      expect(windowScrollTo).toHaveBeenCalledWith({ top: 0 });
    });
  });
});
