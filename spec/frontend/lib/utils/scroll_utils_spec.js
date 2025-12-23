import {
  isScrolledToBottom,
  isScrolledToTop,
  scrollDown,
  scrollUp,
  scrollTo,
  scrollToElement,
  smoothScrollTop,
  preventScrollToFragment,
} from '~/lib/utils/scroll_utils';
import { setHTMLFixture } from 'helpers/fixtures';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/constants';
import { getScrollingElement } from '~/lib/utils/panels';

jest.mock('~/lib/utils/panels');

describe('scroll utils', () => {
  describe('isScrolledToBottom', () => {
    it.each`
      context                                                           | scrollTop | scrollHeight | result
      ${'returns false when not scrolled to bottom'}                    | ${0}      | ${2000}      | ${false}
      ${'returns true when scrolled to bottom'}                         | ${1000}   | ${2000}      | ${true}
      ${'returns true when scrolled to bottom with subpixel precision'} | ${999.25} | ${2000}      | ${true}
      ${'returns true when cannot scroll'}                              | ${0}      | ${500}       | ${true}
    `('$context', ({ scrollTop, scrollHeight, result }) => {
      getScrollingElement.mockReturnValue({ scrollTop, clientHeight: 1000, scrollHeight });

      expect(isScrolledToBottom()).toBe(result);
    });

    describe('isScrolledToTop', () => {
      it.each`
        context                                    | scrollTop | scrollHeight | result
        ${'returns true when scrolled to top'}     | ${0}      | ${2000}      | ${true}
        ${'returns true when not scrolled to top'} | ${1000}   | ${2000}      | ${false}
      `('$context', ({ scrollTop, scrollHeight, result }) => {
        getScrollingElement.mockReturnValue({ scrollTop, clientHeight: 1000, scrollHeight });

        expect(isScrolledToTop()).toBe(result);
      });
    });
  });

  describe('scrollDown', () => {
    it('scrolls container to top', () => {
      const scrollToMock = jest.fn();
      getScrollingElement.mockReturnValue({ scrollHeight: 2000, scrollTo: scrollToMock });

      scrollDown();

      expect(scrollToMock).toHaveBeenCalledWith({ top: 2000 });
    });
  });

  describe('scrollUp', () => {
    it('scrolls container to top', () => {
      const scrollToMock = jest.fn();
      getScrollingElement.mockReturnValue({ scrollHeight: 2000, scrollTo: scrollToMock });

      scrollUp();

      expect(scrollToMock).toHaveBeenCalledWith({ top: 0 });
    });
  });

  describe('scrollTo', () => {
    it('calls `scrollTo` on the panel', () => {
      const scrollToMock = jest.fn();
      const element = {};
      getScrollingElement.mockReturnValue({ scrollTo: scrollToMock });

      scrollTo({ top: 0 }, element);

      expect(getScrollingElement).toHaveBeenCalledWith(element);
      expect(scrollToMock).toHaveBeenCalledWith({ top: 0 });
    });
  });

  describe('scrollToElement', () => {
    const elemTop = 100;

    let scrollToMock;

    const createElement = ({ top = elemTop } = {}) => {
      return {
        getBoundingClientRect: () => ({ top }),
      };
    };

    beforeEach(() => {
      scrollToMock = jest.fn();
      getScrollingElement.mockReturnValue({ scrollTo: scrollToMock, scrollTop: 0 });
    });

    describe('scrollToElement with HTMLElement', () => {
      it('scrolls to element', () => {
        scrollToElement(createElement());

        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with behavior: auto', () => {
        scrollToElement(createElement(), { behavior: 'auto' });
        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'auto',
          top: elemTop,
        });
      });

      it('scrolls to element with behavior: instant', () => {
        scrollToElement(createElement(), { behavior: 'instant' });
        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'instant',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        scrollToElement(createElement(), { offset });
        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        const parent = { scrollTo: jest.fn(), scrollTop: 0 };

        scrollToElement(createElement(), { parent });
        expect(parent.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      describe('when prefers-reduced-motion: reduce', () => {
        beforeEach(() => {
          jest.spyOn(window, 'matchMedia').mockReturnValueOnce({ matches: true });
        });

        it('overrides smooth behavior', () => {
          scrollToElement(createElement(), { behavior: 'smooth' });
          expect(scrollToMock).toHaveBeenCalledWith({
            top: elemTop,
            behavior: 'auto',
          });
        });

        it('does not override auto behavior', () => {
          scrollToElement(createElement(), { behavior: 'auto' });
          expect(scrollToMock).toHaveBeenCalledWith({
            top: elemTop,
            behavior: 'auto',
          });
        });

        it('does not override instant behavior', () => {
          scrollToElement(createElement(), { behavior: 'instant' });
          expect(scrollToMock).toHaveBeenCalledWith({
            top: elemTop,
            behavior: 'instant',
          });
        });
      });
    });

    describe('scrollToElement with Selector', () => {
      beforeEach(() => {
        setHTMLFixture(`
          <div id="scroller">
            <div id="element"></div>
          </div>
        `);
        jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: elemTop });
      });

      it('scrolls to element', () => {
        scrollToElement('#element');
        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        scrollToElement('#element', { offset });
        expect(scrollToMock).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        const parent = document.querySelector('#scroller');

        scrollToElement('#element', { parent });
        expect(parent.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });
  });

  describe('smooth_scroll', () => {
    describe('smoothScrollTop', () => {
      it('calls scrollTo with top 0', () => {
        const scrollToMock = jest.fn();
        getScrollingElement.mockReturnValue({ scrollTo: scrollToMock });

        smoothScrollTop();

        expect(scrollToMock).toHaveBeenCalledWith({
          top: 0,
          behavior: 'smooth',
        });
      });
    });
  });

  describe('preventScrollToFragment', () => {
    it('prevents scroll', () => {
      setHTMLFixture(`
        <div id="target"></div>
        <div id="container"><a href="#target">Click me</a></div>
      `);
      Object.defineProperty(getScrollingElement(), 'scrollTop', {
        writable: true,
        value: 40,
      });
      Object.defineProperty(getScrollingElement(), 'scrollLeft', {
        writable: true,
        value: 50,
      });
      const scrollSpy = jest.spyOn(getScrollingElement(), 'scrollTo');
      document.querySelector('#container').addEventListener('click', preventScrollToFragment);
      document.querySelector('a').click();
      expect(document.querySelector('#target').classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(
        true,
      );
      expect(window.location.hash).toBe('#target');
      expect(scrollSpy).toHaveBeenCalledWith({ top: 40, left: 50 });
    });
  });
});
