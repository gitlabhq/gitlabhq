import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { contentTop } from '~/lib/utils/common_utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';

jest.mock('~/lib/utils/common_utils');

function mockStickyHeaderSize(val) {
  contentTop.mockReturnValue(val);
}

describe('scrollToTargetOnResize', () => {
  let cleanup;
  const mockHeaderSize = 50;
  let resizeObserverCallback;
  let mockObserve;
  let mockUnobserve;

  beforeEach(() => {
    mockObserve = jest.fn();
    mockUnobserve = jest.fn();

    global.ResizeObserver = jest.fn((callback) => {
      resizeObserverCallback = callback;
      return {
        observe: mockObserve,
        unobserve: mockUnobserve,
      };
    });

    mockStickyHeaderSize(mockHeaderSize);

    Object.defineProperty(document, 'scrollingElement', {
      value: {
        scrollTo: jest.fn(),
        scrollTop: 0,
        scrollHeight: 1000,
      },
      writable: true,
    });

    setHTMLFixture(
      `<div id="content-body">
        <div id="target-element">Target content</div>
        <div id="other-content">Other content</div>
      </div>`,
    );
  });

  afterEach(() => {
    if (cleanup) {
      cleanup();
    }
    contentTop.mockReset();
    resetHTMLFixture();
    jest.restoreAllMocks();
  });

  describe('initialization and basic functionality', () => {
    it('returns null if no targetId is provided and no hash exists', () => {
      Object.defineProperty(window, 'location', {
        value: { hash: '' },
        writable: true,
      });

      const result = scrollToTargetOnResize();

      expect(result).toBeNull();
      expect(mockObserve).not.toHaveBeenCalled();
    });

    it('observes the container element on initialization', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      expect(mockObserve).toHaveBeenCalledWith(document.querySelector('#content-body'));
    });

    it('uses window.location.hash if no targetId is provided', () => {
      Object.defineProperty(window, 'location', {
        value: { hash: '#target-element' },
        writable: true,
      });

      const getBoundingClientRectSpy = jest
        .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
        .mockReturnValue({ top: 200 });

      cleanup = scrollToTargetOnResize({ container: '#content-body' });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(getBoundingClientRectSpy).toHaveBeenCalled();
      expect(document.scrollingElement.scrollTo).toHaveBeenCalled();
    });

    it('returns a cleanup function that stops observing', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      expect(typeof cleanup).toBe('function');

      cleanup();

      jest.runAllTimers();

      expect(mockUnobserve).toHaveBeenCalledWith(document.querySelector('#content-body'));
    });
  });

  describe('scrolling behavior', () => {
    beforeEach(() => {
      jest
        .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
        .mockReturnValue({ top: 200 });
    });

    it('scrolls to keep target at top minus header size on resize', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
        top: 200 - 0 - mockHeaderSize,
        behavior: 'instant',
      });
    });

    it('does not scroll when an element other than body is focused', () => {
      const otherElement = document.getElementById('other-content');
      jest.spyOn(document, 'activeElement', 'get').mockReturnValue(otherElement);

      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(document.scrollingElement.scrollTo).not.toHaveBeenCalled();
    });

    it('does nothing if target element does not exist', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'non-existent-id',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(document.scrollingElement.scrollTo).not.toHaveBeenCalled();
    });

    it('maintains scroll position relative to target after user scroll', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
        top: 150,
        behavior: 'instant',
      });

      document.scrollingElement.scrollTop = 100;

      jest
        .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
        .mockReturnValue({ top: 100 });

      window.dispatchEvent(new Event('scroll'));

      jest
        .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
        .mockReturnValue({ top: 200 });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(document.scrollingElement.scrollTo).toHaveBeenLastCalledWith({
        top: 200,
        behavior: 'instant',
      });
    });
  });

  describe('intersection observer', () => {
    let intersectionCallback;
    let observeSpy;
    let unobserveSpy;
    let disconnectSpy;

    beforeEach(() => {
      observeSpy = jest.fn();
      unobserveSpy = jest.fn();
      disconnectSpy = jest.fn();

      global.IntersectionObserver = jest.fn((callback) => {
        intersectionCallback = callback;
        return {
          observe: observeSpy,
          unobserve: unobserveSpy,
          disconnect: disconnectSpy,
        };
      });

      jest
        .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
        .mockReturnValue({ top: 200 });
    });

    it('creates intersection observer after first resize', () => {
      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      expect(global.IntersectionObserver).toHaveBeenCalled();
      expect(observeSpy).toHaveBeenCalledWith(document.getElementById('target-element'));
    });

    it('cleans up when target is scrolled out of view', () => {
      jest.useFakeTimers();

      cleanup = scrollToTargetOnResize({
        targetId: 'target-element',
        container: '#content-body',
      });

      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

      intersectionCallback([{ isIntersecting: false }]);

      jest.runAllTimers();

      expect(unobserveSpy).toHaveBeenCalledWith(document.getElementById('target-element'));
      expect(disconnectSpy).toHaveBeenCalled();
      expect(mockUnobserve).toHaveBeenCalledWith(document.querySelector('#content-body'));

      document.getElementById('target-element').remove();

      document.scrollingElement.scrollTo.mockClear();
      resizeObserverCallback([{ target: document.querySelector('#content-body') }]);
      expect(document.scrollingElement.scrollTo).not.toHaveBeenCalled();
    });
  });

  it('ignores large scrollHeight changes', () => {
    jest
      .spyOn(document.getElementById('target-element'), 'getBoundingClientRect')
      .mockReturnValue({ top: 200 });

    cleanup = scrollToTargetOnResize({
      targetId: 'target-element',
      container: '#content-body',
    });

    resizeObserverCallback([{ target: document.querySelector('#content-body') }]);
    expect(document.scrollingElement.scrollTo).toHaveBeenCalled();

    document.scrollingElement.scrollTo.mockClear();

    document.scrollingElement.scrollHeight = 1200;

    window.dispatchEvent(new Event('scroll'));

    resizeObserverCallback([{ target: document.querySelector('#content-body') }]);

    expect(document.scrollingElement.scrollTo).toHaveBeenCalledWith({
      top: 150,
      behavior: 'instant',
    });
  });
});
