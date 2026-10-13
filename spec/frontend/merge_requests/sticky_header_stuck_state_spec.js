import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import {
  observeStickyHeaderStuckState,
  STICKY_HEADER_OBSERVED_CLASS,
  STICKY_HEADER_STUCK_CLASS,
} from '~/merge_requests/sticky_header_stuck_state';

describe('observeStickyHeaderStuckState', () => {
  const { trigger } = useMockIntersectionObserver();
  let sentinel;
  let target;

  beforeEach(() => {
    sentinel = document.createElement('div');
    target = document.createElement('div');
  });

  it('marks the target as observed', () => {
    observeStickyHeaderStuckState(sentinel, target);

    expect(target.classList.contains(STICKY_HEADER_OBSERVED_CLASS)).toBe(true);
  });

  it('adds the stuck class when the sentinel scrolls out of view', () => {
    observeStickyHeaderStuckState(sentinel, target);

    trigger(sentinel, { entry: { isIntersecting: false } });

    expect(target.classList.contains(STICKY_HEADER_STUCK_CLASS)).toBe(true);
  });

  it('removes the stuck class when the sentinel scrolls back into view', () => {
    observeStickyHeaderStuckState(sentinel, target);

    trigger(sentinel, { entry: { isIntersecting: false } });
    trigger(sentinel, { entry: { isIntersecting: true } });

    expect(target.classList.contains(STICKY_HEADER_STUCK_CLASS)).toBe(false);
  });

  it('passes stickyTop as a negative top rootMargin so the toggle fires when the header pins', () => {
    observeStickyHeaderStuckState(sentinel, target, 100);

    expect(global.IntersectionObserver).toHaveBeenCalledWith(expect.any(Function), {
      rootMargin: '-100px 0px 0px 0px',
    });
  });

  it('returns the observer so the caller can disconnect it', () => {
    const observer = observeStickyHeaderStuckState(sentinel, target);

    expect(observer.disconnect).toEqual(expect.any(Function));
  });

  it.each([
    ['sentinel', () => [null, target]],
    ['target', () => [sentinel, null]],
  ])('does not observe without a %s', (_, getArgs) => {
    expect(observeStickyHeaderStuckState(...getArgs())).toBeNull();
    expect(global.IntersectionObserver).not.toHaveBeenCalled();
    expect(target.classList.contains(STICKY_HEADER_OBSERVED_CLASS)).toBe(false);
  });
});
