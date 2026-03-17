import {
  createItemVisibilityObserver,
  observeElements,
  observeElementsByIds,
} from '~/lib/utils/lazy_render_utils';

describe('lazy_render_utils', () => {
  describe('createItemVisibilityObserver', () => {
    let originalIntersectionObserver;

    beforeEach(() => {
      originalIntersectionObserver = global.IntersectionObserver;
    });

    afterEach(() => {
      global.IntersectionObserver = originalIntersectionObserver;
    });

    it('creates an IntersectionObserver instance', () => {
      const observer = createItemVisibilityObserver(jest.fn());

      expect(observer).toBeInstanceOf(IntersectionObserver);
      observer.disconnect();
    });

    it('creates observer with scrollMargin option and custom root element', () => {
      const customRoot = document.createElement('div');
      const mockIntersectionObserver = jest.fn();
      global.IntersectionObserver = mockIntersectionObserver;
      createItemVisibilityObserver(jest.fn(), { rootElement: customRoot });

      expect(mockIntersectionObserver).toHaveBeenCalledWith(expect.any(Function), {
        root: customRoot,
        scrollMargin: '1500px',
      });
    });

    it('creates observer with null root when no root element provided', () => {
      const mockIntersectionObserver = jest.fn();
      global.IntersectionObserver = mockIntersectionObserver;
      createItemVisibilityObserver(jest.fn());

      expect(mockIntersectionObserver).toHaveBeenCalledWith(expect.any(Function), {
        root: null,
        scrollMargin: '1500px',
      });
    });

    it('unobserves target after first intersection when once is true', () => {
      const target = document.createElement('div');
      target.dataset.itemId = 'test-1';
      const unobserve = jest.fn();
      const setItemVisibility = jest.fn();
      global.IntersectionObserver = jest.fn((cb) => ({
        observe: () => cb([{ target, isIntersecting: true }]),
        unobserve,
        disconnect: jest.fn(),
      }));

      createItemVisibilityObserver(setItemVisibility, { once: true }).observe(target);

      expect(setItemVisibility).toHaveBeenCalledWith('test-1', true);
      expect(unobserve).toHaveBeenCalledWith(target);
    });

    it('skips non-intersecting entries when once is true', () => {
      const target = document.createElement('div');
      target.dataset.itemId = 'test-1';
      const setItemVisibility = jest.fn();
      global.IntersectionObserver = jest.fn((cb) => ({
        observe: () => cb([{ target, isIntersecting: false }]),
        unobserve: jest.fn(),
        disconnect: jest.fn(),
      }));

      createItemVisibilityObserver(setItemVisibility, { once: true }).observe(target);

      expect(setItemVisibility).not.toHaveBeenCalled();
    });
  });

  describe('observeElements', () => {
    it('observes all elements matching the default selector', () => {
      const container = document.createElement('div');
      container.innerHTML = '<li data-item-id="1"></li><li data-item-id="2"></li>';
      const observer = { observe: jest.fn() };

      observeElements(container, observer);

      expect(observer.observe).toHaveBeenCalledTimes(2);
    });

    it('observes elements matching a custom selector', () => {
      const container = document.createElement('div');
      container.innerHTML = '<div class="item"></div><div class="item"></div>';
      const observer = { observe: jest.fn() };

      observeElements(container, observer, '.item');

      expect(observer.observe).toHaveBeenCalledTimes(2);
    });
  });

  describe('observeElementsByIds', () => {
    it('observes elements matching the given IDs', () => {
      const container = document.createElement('div');
      container.innerHTML =
        '<div data-item-id="a"></div><div data-item-id="b"></div><div data-item-id="c"></div>';
      const observer = { observe: jest.fn() };

      observeElementsByIds(container, observer, ['a', 'c']);

      expect(observer.observe).toHaveBeenCalledTimes(2);
      expect(observer.observe).toHaveBeenCalledWith(container.querySelector('[data-item-id="a"]'));
      expect(observer.observe).toHaveBeenCalledWith(container.querySelector('[data-item-id="c"]'));
    });

    it('skips IDs that do not exist in the container', () => {
      const container = document.createElement('div');
      container.innerHTML = '<div data-item-id="a"></div>';
      const observer = { observe: jest.fn() };

      observeElementsByIds(container, observer, ['a', 'missing']);

      expect(observer.observe).toHaveBeenCalledTimes(1);
    });
  });
});
