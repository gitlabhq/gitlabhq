import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { getPanelElement, getScrollingElement } from '~/lib/utils/panels';

describe('Panels utils', () => {
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
    getScrollingElement.cache.clear(); // clear lodash's memoize cache
    window.gon = { features: null };
    resetHTMLFixture();
  });

  describe('getPanelElement', () => {
    it('returns static panel element', () => {
      expect(getPanelElement(findElem())).toBe(findStaticPanelInner());
    });

    it('returns dynamic panel element', () => {
      expect(getPanelElement(findElemInDynamicPanel())).toBe(findDynamicPanelInner());
    });

    it('returns null without context', () => {
      expect(getPanelElement()).toBeNull();
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
});
