import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { PanelBreakpointManager } from '~/panel_breakpoint_instance';

describe('PanelBreakpointManager', () => {
  let panelBreakpointManager;
  let panelClientWidth;
  let resizeObserverCallback;
  let mockObserver;

  const setHTMLFixturePanel = () => {
    setHTMLFixture(`
      <div class="js-static-panel-inner">
        <main id="content-body"></main>
      </div>
    `);
  };

  const setPanelWidth = (width) => {
    panelClientWidth = width;
    jest
      .spyOn(document.querySelector('#content-body'), 'clientWidth', 'get')
      .mockImplementation(() => panelClientWidth);
  };

  const mockResizePanel = (width) => {
    panelClientWidth = width;
    resizeObserverCallback([{ contentRect: { width } }]);
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

  describe('availableWidth', () => {
    it('returns the main container width when available', () => {
      setHTMLFixturePanel();
      setPanelWidth(800);
      panelBreakpointManager = new PanelBreakpointManager();

      expect(panelBreakpointManager.availableWidth()).toBe(800);
    });

    it('falls back to window width when main container is not available', () => {
      window.innerWidth = 1024;
      panelBreakpointManager = new PanelBreakpointManager();

      expect(panelBreakpointManager.availableWidth()).toBe(1024);
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
    describe.each(expectedBreakpoints)('with panel of width $width', ({ width, bp }) => {
      beforeEach(() => {
        setHTMLFixturePanel();
        setPanelWidth(width);
        panelBreakpointManager = new PanelBreakpointManager();
      });

      it(`returns breakpoint ${bp}`, () => {
        expect(panelBreakpointManager.getBreakpointSize()).toBe(bp);
      });
    });

    describe.each(expectedBreakpoints)('with window of width $width', ({ width, bp }) => {
      beforeEach(() => {
        window.innerWidth = width;
        panelBreakpointManager = new PanelBreakpointManager();
      });

      it(`returns breakpoint ${bp}`, () => {
        expect(panelBreakpointManager.getBreakpointSize()).toBe(bp);
      });
    });
  });

  describe('isDesktop', () => {
    describe.each(expectedBreakpoints)('with panel of width $width', ({ width, isDesktop }) => {
      beforeEach(() => {
        setHTMLFixturePanel();
        setPanelWidth(width);
        panelBreakpointManager = new PanelBreakpointManager();
      });

      it(`returns isDesktop = ${isDesktop}`, () => {
        expect(panelBreakpointManager.isDesktop()).toBe(isDesktop);
      });
    });
  });

  describe('isBreakpointUp', () => {
    beforeEach(() => {
      setHTMLFixturePanel();
      setPanelWidth(900); // md breakpoint
      panelBreakpointManager = new PanelBreakpointManager();
    });

    it('returns true when current breakpoint is greater than target', () => {
      expect(panelBreakpointManager.isBreakpointUp('sm')).toBe(true);
      expect(panelBreakpointManager.isBreakpointUp('xs')).toBe(true);
    });

    it('returns true when current breakpoint equals target', () => {
      expect(panelBreakpointManager.isBreakpointUp('md')).toBe(true);
    });

    it('returns false when current breakpoint is less than target', () => {
      expect(panelBreakpointManager.isBreakpointUp('lg')).toBe(false);
      expect(panelBreakpointManager.isBreakpointUp('xl')).toBe(false);
    });
  });

  describe('isBreakpointDown', () => {
    beforeEach(() => {
      setHTMLFixturePanel();
      setPanelWidth(900); // md breakpoint
      panelBreakpointManager = new PanelBreakpointManager();
    });

    it('returns true when current breakpoint is less than target', () => {
      expect(panelBreakpointManager.isBreakpointDown('lg')).toBe(true);
      expect(panelBreakpointManager.isBreakpointDown('xl')).toBe(true);
    });

    it('returns true when current breakpoint equals target', () => {
      expect(panelBreakpointManager.isBreakpointDown('md')).toBe(true);
    });

    it('returns false when current breakpoint is greater than target', () => {
      expect(panelBreakpointManager.isBreakpointDown('sm')).toBe(false);
      expect(panelBreakpointManager.isBreakpointDown('xs')).toBe(false);
    });
  });

  describe('resize listener', () => {
    it('calls handler when panel is resized', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addResizeListener(handler);

      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1100);

      expect(handler).toHaveBeenCalledWith(1100, 1000);
    });

    it('calls multiple handlers on resize', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler1 = jest.fn();
      const handler2 = jest.fn();
      panelBreakpointManager.addResizeListener(handler1);
      panelBreakpointManager.addResizeListener(handler2);

      mockResizePanel(1100);

      expect(handler1).toHaveBeenCalledWith(1100, 1000);
      expect(handler2).toHaveBeenCalledWith(1100, 1000);
    });

    it('does not call handler if width has not changed', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addResizeListener(handler);

      mockResizePanel(1000);

      expect(handler).not.toHaveBeenCalled();
    });

    it('unsubscribes', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addResizeListener(handler);

      mockResizePanel(800);

      panelBreakpointManager.removeResizeListener(handler);

      mockResizePanel(1200);

      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('breakpoint listener', () => {
    it('calls handler when breakpoint changes', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addBreakpointListener(handler);

      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1200);

      expect(handler).toHaveBeenCalledWith('xl', 'lg');
    });

    it('calls multiple handlers on resize', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      const handler2 = jest.fn();
      panelBreakpointManager.addBreakpointListener(handler);
      panelBreakpointManager.addBreakpointListener(handler2);

      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1200);

      expect(handler).toHaveBeenCalledWith('xl', 'lg');
      expect(handler2).toHaveBeenCalledWith('xl', 'lg');
    });

    it('does not call handler if width has not changed', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addBreakpointListener(handler);

      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1100);

      expect(handler).not.toHaveBeenCalled();
    });

    it('unsubscribes', () => {
      setHTMLFixturePanel();
      setPanelWidth(1000);
      panelBreakpointManager = new PanelBreakpointManager();

      const handler = jest.fn();
      panelBreakpointManager.addBreakpointListener(handler);

      expect(global.ResizeObserver).toHaveBeenCalled();
      expect(mockObserver.observe).toHaveBeenCalled();

      mockResizePanel(1200);

      panelBreakpointManager.removeBreakpointListener(handler);

      mockResizePanel(1000);

      expect(handler).toHaveBeenCalledTimes(1);
    });
  });
});
