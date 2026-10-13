export const STICKY_HEADER_OBSERVED_CLASS = 'is-sticky-header-observed';
export const STICKY_HEADER_STUCK_CLASS = 'is-sticky-header-stuck';

// The flash container sits outside the sticky header, so it can't use the header's
// `scroll-state(stuck: top)` query. We watch a sentinel above the header instead: once it
// scrolls past the point where the header pins, the header is stuck.
//
// `stickyTop` is the distance the header pins from the viewport top (the application header
// height). Feeding it as a negative top `rootMargin` moves the observer's trigger line down to
// that pin point, so the stuck class flips exactly when the header sticks rather than when the
// sentinel reaches the very top of the viewport.
export const observeStickyHeaderStuckState = (sentinel, target, stickyTop = 0) => {
  if (!sentinel || !target) return null;

  // Styles keyed on the stuck class only apply where this observer keeps it up to date
  target.classList.add(STICKY_HEADER_OBSERVED_CLASS);

  const observer = new IntersectionObserver(
    ([entry]) => {
      target.classList.toggle(STICKY_HEADER_STUCK_CLASS, !entry.isIntersecting);
    },
    { rootMargin: `-${stickyTop}px 0px 0px 0px` },
  );
  observer.observe(sentinel);

  return observer;
};
