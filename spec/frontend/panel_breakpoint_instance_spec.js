import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

describe('PanelBreakpointInstance', () => {
  let panelClientWidth;
  let resizeObserverCallback;
  let mockObserver;

  const setHTMLFixturePanel = (width = 1000) => {
    setHTMLFixture(`
      <div class="js-static-panel-inner">
        <main id="content-body"></div>
      </div>
    `);

    panelClientWidth = width;
    jest
      .spyOn(document.querySelector('#content-body'), 'clientWidth', 'get')
      .mockImplementation(() => panelClientWidth);
  };

  const mockResizePanel = (width) => {
    panelClientWidth = width;
    resizeObserverCallback([{}]);
  };

  beforeEach(() => {
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 1000,
    });

    // Mock ResizeObserver
    global.ResizeObserver = jest.fn().mockImplementation((callback) => {
      resizeObserverCallback = callback;
      mockObserver = {
        observe: jest.fn(),
        unobserve: jest.fn(),
        disconnect: jest.fn(),
      };

      return mockObserver;
    });
  });

  afterEach(() => {
    resetHTMLFixture();

    global.ResizeObserver = null;
    jest.clearAllMocks();
  });

  describe('windowWidth', () => {
    it('returns the window inner width', () => {
      window.innerWidth = 1024;

      expect(PanelBreakpointInstance.windowWidth()).toBe(1024);
    });
  });

  describe('availableWidth', () => {
    it('returns the main container width when available', () => {
      setHTMLFixturePanel(800);

      expect(PanelBreakpointInstance.availableWidth()).toBe(800);
    });

    it('falls back to window width when main container is not available', () => {
      window.innerWidth = 1024;

      expect(PanelBreakpointInstance.availableWidth()).toBe(1024);
    });
  });

  const expectedBreakpoints = [
    { width: 1200, bp: 'xl', isDesktop: true },
    { width: 1500, bp: 'xl', isDesktop: true },
    { width: 1100, bp: 'lg', isDesktop: true },
    { width: 992, bp: 'lg', isDesktop: true },
    { width: 900, bp: 'md', isDesktop: false },
    { width: 768, bp: 'md', isDesktop: false },
    { width: 700, bp: 'sm', isDesktop: false },
    { width: 576, bp: 'sm', isDesktop: false },
    { width: 500, bp: 'xs', isDesktop: false },
    { width: 0, bp: 'xs', isDesktop: false },
  ];

  describe('getBreakpointSize', () => {
    describe.each(expectedBreakpoints)('with panel of width $width', ({ width, bp, isDesktop }) => {
      beforeEach(() => {
        setHTMLFixturePanel(width);
      });

      it(`returns breakpoint ${bp}`, () => {
        expect(PanelBreakpointInstance.getBreakpointSize()).toBe(bp);
      });

      it(`returns isDesktop = ${isDesktop}`, () => {
        expect(PanelBreakpointInstance.isDesktop()).toBe(isDesktop);
      });
    });

    describe.each(expectedBreakpoints)(
      'with window of width $width',
      ({ width, bp, isDesktop }) => {
        beforeEach(() => {
          window.innerWidth = width;
        });

        it(`returns breakpoint ${bp}`, () => {
          expect(PanelBreakpointInstance.getBreakpointSize()).toBe(bp);
        });

        it(`returns isDesktop = ${isDesktop}`, () => {
          expect(PanelBreakpointInstance.isDesktop()).toBe(isDesktop);
        });
      },
    );
  });

  describe('addResizeListener', () => {
    it('adds handlers when main container exists', () => {
      setHTMLFixturePanel();

      const handler1 = jest.fn();
      const handler2 = jest.fn();
      PanelBreakpointInstance.addResizeListener(handler1);
      PanelBreakpointInstance.addResizeListener(handler2);

      // Verify ResizeObserver was created and is observing
      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1100);

      expect(handler1).toHaveBeenCalled();
      expect(handler2).toHaveBeenCalled();

      PanelBreakpointInstance.removeResizeListener(handler1);
      PanelBreakpointInstance.removeResizeListener(handler2);
    });

    it('adds event listener to window when main container does not exist', () => {
      const addEventListenerSpy = jest.spyOn(window, 'addEventListener');
      const handler = jest.fn();

      PanelBreakpointInstance.addResizeListener(handler);

      expect(addEventListenerSpy).toHaveBeenCalledWith('resize', handler);
    });
  });

  describe('removeResizeListener', () => {
    it('removes handler from handlers array when main container exists', () => {
      const handler1 = jest.fn();
      setHTMLFixturePanel();

      PanelBreakpointInstance.addResizeListener(handler1);

      expect(handler1).toHaveBeenCalledTimes(0);

      mockResizePanel(1100);

      expect(handler1).toHaveBeenCalledTimes(1);

      PanelBreakpointInstance.removeResizeListener(handler1);

      mockResizePanel(1200);

      expect(handler1).toHaveBeenCalledTimes(1);
      expect(mockObserver.disconnect).toHaveBeenCalled();
    });

    it('removes event listener from window when main container does not exist', () => {
      const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
      const handler = jest.fn();

      PanelBreakpointInstance.removeResizeListener(handler);

      expect(removeEventListenerSpy).toHaveBeenCalledWith('resize', handler);
    });
  });
});
