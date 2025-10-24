import {
  isScrolledToBottom,
  isScrolledToTop,
  scrollDown,
  scrollUp,
  scrollTo,
  getScrollingElement,
  scrollToElement,
  smoothScrollTop,
} from '~/lib/utils/scroll_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('scroll utils', () => {
  const findElem = () => document.querySelector('#element');
  const findElemInDynamicPanel = () => document.querySelector('#element-in-dynamic-panel');
  const findStaticPanelInner = () => document.querySelector('.js-static-panel-inner');
  const findDynamicPanelInner = () => document.querySelector('.js-dynamic-panel-inner');
  const findDocumentScrollingElement = () => document.scrollingElement;

  const setupEnvironment = ({
    projectStudioEnabled = false,
    getBoundingClientRect,
    ...getters
  } = {}) => {
    if (projectStudioEnabled) {
      window.gon = { features: { projectStudioEnabled: true } };

      setHTMLFixture(`
        <div>
          <div class="js-static-panel-inner">
            <div id="element"></div>
          </div>
          <div class="js-dynamic-panel-inner">
            <div id="element-in-dynamic-panel"></div>
          </div>
        </div>
      `);

      Object.entries(getters).forEach(([name, value]) => {
        jest.spyOn(findStaticPanelInner(), name, 'get').mockReturnValue(value);
        jest.spyOn(findDynamicPanelInner(), name, 'get').mockReturnValue(value);
      });
    } else {
      window.gon = { features: {} };

      setHTMLFixture('<div id="scroller"><div id="element" /></div>');

      Object.entries(getters).forEach(([name, value]) => {
        jest.spyOn(findDocumentScrollingElement(), name, 'get').mockReturnValue(value);
      });
    }

    if (getBoundingClientRect) {
      if (findElem()) {
        jest.spyOn(findElem(), 'getBoundingClientRect').mockReturnValue(getBoundingClientRect);
      }
      if (findElemInDynamicPanel()) {
        jest
          .spyOn(findElemInDynamicPanel(), 'getBoundingClientRect')
          .mockReturnValue(getBoundingClientRect);
      }
    }
  };

  afterEach(() => {
    window.gon = { features: null };
    getScrollingElement.cache.clear(); // clear lodash's memoize cache
    resetHTMLFixture();
  });

  describe.each`
    case                                    | projectStudioEnabled
    ${'with window as scrolling container'} | ${true}
    ${'with panel as scrolling container'}  | ${false}
  `('$case', ({ projectStudioEnabled }) => {
    describe('isScrolledToBottom', () => {
      it.each`
        context                                                           | scrollTop | scrollHeight | result
        ${'returns false when not scrolled to bottom'}                    | ${0}      | ${2000}      | ${false}
        ${'returns true when scrolled to bottom'}                         | ${1000}   | ${2000}      | ${true}
        ${'returns true when scrolled to bottom with subpixel precision'} | ${999.25} | ${2000}      | ${true}
        ${'returns true when cannot scroll'}                              | ${0}      | ${500}       | ${true}
      `('$context', ({ scrollTop, scrollHeight, result }) => {
        setupEnvironment({ projectStudioEnabled, scrollTop, clientHeight: 1000, scrollHeight });

        expect(isScrolledToBottom()).toBe(result);
      });
    });

    describe('isScrolledToTop', () => {
      it.each`
        context                                    | scrollTop | scrollHeight | result
        ${'returns true when scrolled to top'}     | ${0}      | ${2000}      | ${true}
        ${'returns true when not scrolled to top'} | ${1000}   | ${2000}      | ${false}
      `('$context', ({ scrollTop, scrollHeight, result }) => {
        setupEnvironment({ projectStudioEnabled, scrollTop, clientHeight: 1000, scrollHeight });

        expect(isScrolledToTop()).toBe(result);
      });
    });
  });

  describe('scrollDown', () => {
    it('scrolls container to top', () => {
      setupEnvironment({ projectStudioEnabled: true, scrollHeight: 2000 });

      scrollDown();

      expect(findStaticPanelInner().scrollTo).toHaveBeenCalledWith({ top: 2000 });
    });

    it('scrolls window to top', () => {
      setupEnvironment({ scrollHeight: 2000 });

      scrollDown();

      expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({ top: 2000 });
    });
  });

  describe('scrollUp', () => {
    it('scrolls container to top', () => {
      setupEnvironment({ projectStudioEnabled: true, scrollHeight: 2000 });

      scrollUp();

      expect(findStaticPanelInner().scrollTo).toHaveBeenCalledWith({ top: 0 });
    });

    it('scrolls window to top', () => {
      setupEnvironment({ scrollHeight: 2000 });

      scrollUp();

      expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({ top: 0 });
    });
  });

  describe('scrollTo', () => {
    describe('when inside a panel', () => {
      it('calls `scrollTo` on the panel', () => {
        setupEnvironment({ projectStudioEnabled: true });

        scrollTo({ top: 0 }, findElem());

        expect(findStaticPanelInner().scrollTo).toHaveBeenCalledWith({ top: 0 });
      });
    });
    describe('when not inside a panel', () => {
      it('calls `scrollTo` on the window', () => {
        scrollTo({ top: 0 }, document.body);

        expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({ top: 0 });
      });
    });
  });

  describe('getScrollingElement', () => {
    it('handles null/undefined elements', () => {
      setupEnvironment({ projectStudioEnabled: false });

      expect(getScrollingElement(null)).toBe(document.scrollingElement);
      expect(getScrollingElement(undefined)).toBe(document.scrollingElement);
    });

    describe('when element is inside a panel', () => {
      it.each`
        panelType    | elementFinder             | innerClass
        ${'static'}  | ${findElem}               | ${'js-static-panel-inner'}
        ${'dynamic'} | ${findElemInDynamicPanel} | ${'js-dynamic-panel-inner'}
      `('returns $panelType panel inner element', ({ elementFinder, innerClass }) => {
        setupEnvironment({ projectStudioEnabled: true });

        const element = elementFinder();
        const container = document.querySelector(`.${innerClass}`);

        expect(getScrollingElement(element)).toBe(container);
      });
    });

    describe('when element is not inside a proper panel', () => {
      it.each`
        scenario                 | html
        ${'no panel'}            | ${'<div id="element" />'}
        ${'no inner'}            | ${'<div class="js-static-panel"><div id="element"></div></div>'}
        ${'no inner in dynamic'} | ${'<div class="js-dynamic-panel"><div id="element"></div></div>'}
      `('returns window as fallback for $scenario', ({ html }) => {
        window.gon = { features: { projectStudioEnabled: true } };
        setHTMLFixture(html);

        const element = document.getElementById('element');

        expect(getScrollingElement(element)).toBe(document.scrollingElement);
      });
    });
  });

  describe('scrollToElement', () => {
    const elemTop = 100;

    describe('when project studio is disabled', () => {
      beforeEach(() => {
        setupEnvironment({ projectStudioEnabled: false, getBoundingClientRect: { top: elemTop } });
      });

      describe('scrollToElement with HTMLElement', () => {
        it('scrolls to element', () => {
          scrollToElement(findElem());

          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
            behavior: 'smooth',
            top: elemTop,
          });
        });

        it('scrolls to element with behavior: auto', () => {
          scrollToElement(findElem(), { behavior: 'auto' });
          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
            behavior: 'auto',
            top: elemTop,
          });
        });

        it('scrolls to element with behavior: instant', () => {
          scrollToElement(findElem(), { behavior: 'instant' });
          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
            behavior: 'instant',
            top: elemTop,
          });
        });

        it('scrolls to element with offset', () => {
          const offset = 50;
          scrollToElement(findElem(), { offset });
          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
            behavior: 'smooth',
            top: elemTop + offset,
          });
        });

        it('scrolls to element within a parent', () => {
          const parent = document.querySelector('#scroller');

          scrollToElement(findElem(), { parent });
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
            scrollToElement(findElem(), { behavior: 'smooth' });
            expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
              top: elemTop,
              behavior: 'auto',
            });
          });

          it('does not override auto behavior', () => {
            scrollToElement(findElem(), { behavior: 'auto' });
            expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
              top: elemTop,
              behavior: 'auto',
            });
          });

          it('does not override instant behavior', () => {
            scrollToElement(findElem(), { behavior: 'instant' });
            expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
              top: elemTop,
              behavior: 'instant',
            });
          });
        });
      });

      describe('scrollToElement with Selector', () => {
        it('scrolls to element', () => {
          scrollToElement('#element');
          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
            behavior: 'smooth',
            top: elemTop,
          });
        });

        it('scrolls to element with offset', () => {
          const offset = 50;
          scrollToElement('#element', { offset });
          expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
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

    describe('when project studio is enabled', () => {
      beforeEach(() => {
        setupEnvironment({ projectStudioEnabled: true, getBoundingClientRect: { top: elemTop } });
      });

      it('scrolls the static panel', () => {
        scrollToElement(findElem());
        expect(findStaticPanelInner().scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls the dynamic panel', () => {
        scrollToElement(findElemInDynamicPanel());

        expect(findDynamicPanelInner().scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });
  });

  describe('smooth_scroll', () => {
    describe('smoothScrollTop', () => {
      it('calls scrollTo with top 0', () => {
        smoothScrollTop();

        expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
          top: 0,
          behavior: 'smooth',
        });
      });
    });
  });
});
