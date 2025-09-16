import {
  DynamicHeightManager,
  createDynamicHeightManager,
} from '~/vue_shared/utils/dynamic_height';

// Mock debounce to make tests synchronous
jest.mock('lodash', () => ({
  debounce: jest.fn((fn) => fn),
}));

describe('DynamicHeightManager', () => {
  let mockElement;
  let mockContentWrapper;
  let manager;

  beforeEach(() => {
    // Create mock DOM structure
    mockContentWrapper = document.createElement('div');
    mockContentWrapper.className = 'content-wrapper';
    jest.spyOn(mockContentWrapper, 'getBoundingClientRect').mockImplementation(() => {
      return { height: 800 };
    });

    mockElement = document.createElement('div');
    jest.spyOn(mockElement, 'getBoundingClientRect').mockImplementation(() => {
      return { height: 200 };
    });

    Object.defineProperty(mockElement, 'style', {
      value: { height: '' },
      writable: true,
    });

    // Set up DOM hierarchy
    mockContentWrapper.appendChild(mockElement);
    document.body.appendChild(mockContentWrapper);

    // Mock closest method
    jest.spyOn(mockElement, 'closest').mockReturnValue(mockContentWrapper);

    // Mock ResizeObserver
    global.ResizeObserver = jest.fn().mockImplementation((callback) => ({
      observe: jest.fn(),
      disconnect: jest.fn(),
      callback,
    }));
  });

  afterEach(() => {
    if (manager) {
      manager.destroy();
    }
    if (document.body.contains(mockContentWrapper)) {
      document.body.removeChild(mockContentWrapper);
    }
    jest.restoreAllMocks();
  });

  describe('constructor', () => {
    it('initializes with default options', () => {
      manager = new DynamicHeightManager(mockElement);

      expect(manager.element).toBe(mockElement);
      expect(manager.options).toEqual({
        closest: '.content-wrapper',
        minHeight: 500,
        debounce: 100, // CONTENT_UPDATE_DEBOUNCE default value
      });
    });

    it('merges custom options with defaults', () => {
      const customOptions = {
        closest: '.custom-wrapper',
        minHeight: 300,
        debounce: 100,
      };

      manager = new DynamicHeightManager(mockElement, customOptions);

      expect(manager.options).toEqual(customOptions);
    });
  });

  describe('init', () => {
    it('sets initial height and creates ResizeObserver', () => {
      manager = new DynamicHeightManager(mockElement);
      jest.spyOn(manager, 'setHeight');

      manager.init();

      expect(manager.setHeight).toHaveBeenCalled();
      expect(global.ResizeObserver).toHaveBeenCalledWith(expect.any(Function));
      expect(manager.resizeObserver.observe).toHaveBeenCalledWith(document.documentElement);
    });

    it('does not reinitialize if already initialized', () => {
      manager = new DynamicHeightManager(mockElement);
      manager.init();

      const originalObserver = manager.resizeObserver;
      manager.init();

      expect(manager.resizeObserver).toBe(originalObserver);
    });

    it('does not initialize if element is null', () => {
      manager = new DynamicHeightManager(null);
      manager.init();

      expect(manager.resizeObserver).toBeNull();
    });
  });

  describe('setHeight', () => {
    beforeEach(() => {
      manager = new DynamicHeightManager(mockElement);
    });

    it('calculates and sets height correctly', () => {
      manager.setHeight();

      const expectedContentHeight = 800 - 200;
      const expectedHeight = `max(calc(100vh - ${expectedContentHeight}px), 500px)`;

      expect(mockElement.style.height).toBe(expectedHeight);
    });

    it('uses custom minHeight when provided', () => {
      manager.options.minHeight = 300;
      manager.setHeight();

      const expectedContentHeight = 800 - 200;
      const expectedHeight = `max(calc(100vh - ${expectedContentHeight}px), 300px)`;

      expect(mockElement.style.height).toBe(expectedHeight);
    });

    it('handles missing content wrapper gracefully', () => {
      mockElement.closest.mockReturnValue(null);
      manager.setHeight();

      const expectedHeight = '';

      expect(mockElement.style.height).toBe(expectedHeight);
    });

    it('does not set height when element is null', () => {
      manager.element = null;
      manager.setHeight();

      expect(mockElement.style.height).toBe('');
    });
  });

  describe('updateOptions', () => {
    beforeEach(() => {
      manager = new DynamicHeightManager(mockElement);
    });

    it('updates options and recalculates height', () => {
      const newOptions = { minHeight: 400 };
      jest.spyOn(manager, 'setHeight');

      manager.updateOptions(newOptions);

      expect(manager.options.minHeight).toBe(400);
      expect(manager.setHeight).toHaveBeenCalled();
    });

    it('updates debounced function when debounce value changes', () => {
      const originalDebouncedFn = manager.debouncedSetHeight;

      manager.updateOptions({ debounce: 200 });

      expect(manager.debouncedSetHeight).not.toBe(originalDebouncedFn);
      expect(manager.options.debounce).toBe(200);
    });
  });

  describe('destroy', () => {
    it('disconnects ResizeObserver', () => {
      manager = new DynamicHeightManager(mockElement);
      manager.init();

      const disconnectSpy = jest.spyOn(manager.resizeObserver, 'disconnect');
      manager.destroy();

      expect(disconnectSpy).toHaveBeenCalled();
      expect(manager.resizeObserver).toBeNull();
    });

    it('handles case when ResizeObserver is null', () => {
      manager = new DynamicHeightManager(mockElement);

      expect(() => manager.destroy()).not.toThrow();
    });
  });

  describe('createDynamicHeightManager', () => {
    it('creates and initializes a manager', () => {
      const mockInit = jest.fn();
      jest.spyOn(DynamicHeightManager.prototype, 'init').mockImplementation(mockInit);

      manager = createDynamicHeightManager(mockElement, { minHeight: 300 });

      expect(manager).toBeInstanceOf(DynamicHeightManager);
      expect(manager.options.minHeight).toBe(300);
      expect(mockInit).toHaveBeenCalled();
    });
  });
});
