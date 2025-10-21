import {
  isScrolledToBottom,
  isScrolledToTop,
  scrollDown,
  scrollUp,
  scrollTo,
  findParentPanelScrollingEl,
  scrollToElement,
  smoothScrollTo,
  smoothScrollTop,
} from '~/lib/utils/scroll_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

const makePanelHtmlStub = (
  outerClass = 'js-static-panel',
  innerClass = 'js-static-panel-inner',
) => {
  return `<div class="${outerClass}">
    <div class="${innerClass}" id="scroller">
      <div id="test" />
    </div>
  </div>`;
};

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

  describe('scrollTo', () => {
    describe('when inside a panel', () => {
      it('calls `scrollTo` on the panel', () => {
        document.body.innerHTML = makePanelHtmlStub();
        const target = document.getElementById('test');
        const scroller = document.getElementById('scroller');
        const scrollerSpy = jest.spyOn(scroller, 'scrollTo');

        scrollTo({ top: 0 }, target);

        expect(scrollerSpy).toHaveBeenCalledWith({ top: 0 });
      });
    });
    describe('when not inside a panel', () => {
      it('calls `scrollTo` on the window', () => {
        const spy = jest.spyOn(window, 'scrollTo');
        scrollTo({ top: 0 }, document.body);
        expect(spy).toHaveBeenCalledWith({ top: 0 });
      });
    });
  });

  describe('findParentPanelScrollingEl', () => {
    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('handles null/undefined elements', () => {
      expect(findParentPanelScrollingEl(null)).toBeNull();
      expect(findParentPanelScrollingEl(undefined)).toBeNull();
    });

    describe('when element is inside a panel', () => {
      it.each`
        panelType    | panelClass            | innerClass
        ${'static'}  | ${'js-static-panel'}  | ${'js-static-panel-inner'}
        ${'dynamic'} | ${'js-dynamic-panel'} | ${'js-dynamic-panel-inner'}
      `('returns $panelType panel inner element', ({ panelClass, innerClass }) => {
        document.body.innerHTML = makePanelHtmlStub(panelClass, innerClass);

        const element = document.getElementById('test');
        const inner = document.querySelector(`.${innerClass}`);

        expect(findParentPanelScrollingEl(element)).toBe(inner);
      });
    });

    describe('when element is not inside a proper panel', () => {
      it.each`
        scenario      | html
        ${'no panel'} | ${'<div id="test" />'}
        ${'no inner'} | ${'<div class="js-static-panel"><div id="test" /></div>'}
      `('returns null for $scenario', ({ html }) => {
        document.body.innerHTML = html;
        const element = document.getElementById('test');

        expect(findParentPanelScrollingEl(element)).toBeNull();
      });
    });
  });

  describe('scrollToElement*', () => {
    let parentElem;
    let elem;
    const windowHeight = 550;
    const elemTop = 100;
    const parentId = 'parent_scroll_test';
    const id = 'scroll_test';

    beforeEach(() => {
      parentElem = document.createElement('div');
      parentElem.id = parentId;
      elem = document.createElement('div');
      elem.id = id;
      parentElem.appendChild(elem);
      document.body.appendChild(parentElem);

      window.innerHeight = windowHeight;
      window.mrTabs = { currentAction: 'show' };

      jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
      jest.spyOn(parentElem, 'scrollTo').mockImplementation(() => {});
      jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: elemTop });
    });

    afterEach(() => {
      window.scrollTo.mockRestore();
      parentElem.scrollTo.mockRestore();
      Element.prototype.getBoundingClientRect.mockRestore();
      elem.remove();
      parentElem.remove();
    });

    describe('scrollToElement with HTMLElement', () => {
      it('scrolls to element', () => {
        scrollToElement(elem);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        scrollToElement(elem, { offset });
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        scrollToElement(elem, { parent: parentElem });
        expect(parentElem.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });

    describe('scrollToElement with Selector', () => {
      it('scrolls to element', () => {
        scrollToElement(`#${id}`);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        scrollToElement(`#${id}`, { offset });
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        scrollToElement(`#${id}`, { parent: `#${parentId}` });
        expect(parentElem.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });

    describe('when project studio is enabled', () => {
      beforeEach(() => {
        window.gon = {
          features: {
            projectStudioEnabled: true,
          },
        };
      });

      it('scrolls the static panel', () => {
        const staticPanelContainer = document.createElement('div');
        staticPanelContainer.classList.add('js-static-panel');

        const staticPanelScroller = document.createElement('div');
        staticPanelScroller.classList.add('js-static-panel-inner');

        staticPanelContainer.appendChild(staticPanelScroller);

        staticPanelScroller.appendChild(elem);

        document.body.appendChild(staticPanelContainer);

        jest.spyOn(staticPanelScroller, 'scrollTo').mockImplementation(() => {});
        jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: elemTop });

        scrollToElement(elem);
        expect(staticPanelScroller.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls the dynamic panel', () => {
        const dynamicPanelContainer = document.createElement('div');
        dynamicPanelContainer.classList.add('js-dynamic-panel');

        const dynamicPanelScroller = document.createElement('div');
        dynamicPanelScroller.classList.add('js-dynamic-panel-inner');

        dynamicPanelContainer.appendChild(dynamicPanelScroller);

        dynamicPanelScroller.appendChild(elem);

        document.body.appendChild(dynamicPanelContainer);

        jest.spyOn(dynamicPanelScroller, 'scrollTo').mockImplementation(() => {});
        jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: elemTop });

        scrollToElement(elem);
        expect(dynamicPanelScroller.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });
  });

  describe('smooth_scroll', () => {
    let scrollToSpy;

    beforeEach(() => {
      scrollToSpy = jest.spyOn(window, 'scrollTo');
    });

    afterEach(() => {
      scrollToSpy.mockRestore();
    });

    describe('smoothScrollTo', () => {
      describe('when user prefers reduced motion', () => {
        beforeEach(() => {
          jest.spyOn(window, 'matchMedia').mockReturnValue({ matches: true });
        });

        it('calls scrollTo with the provided options', () => {
          smoothScrollTo({ top: 100 });

          expect(scrollToSpy).toHaveBeenCalledWith({
            top: 100,
            behavior: expect.stringMatching('auto'),
          });
        });
      });

      describe('when user does not prefer reduced motion', () => {
        beforeEach(() => {
          jest.spyOn(window, 'matchMedia').mockReturnValue({ matches: false });
        });

        it('calls scrollTo with the provided options', () => {
          smoothScrollTo({ top: 100 });

          expect(scrollToSpy).toHaveBeenCalledWith({
            top: 100,
            behavior: expect.stringMatching('smooth'),
          });
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
});
