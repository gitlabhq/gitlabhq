const SETTLE_TIMEOUT = 150;
let activeController;

/**
 * scrollIntoView that re-scrolls on contentvisibilityautostatechange until layout settles.
 * Aborts if the user scrolls manually or another call is made.
 * @param {HTMLElement} element
 * @param {HTMLElement|Document} root - ancestor where contentvisibilityautostatechange bubbles
 * @param {ScrollIntoViewOptions} options
 */
export function settledScrollIntoView(element, root, options = { block: 'start' }) {
  activeController?.abort();
  const controller = new AbortController();
  const { signal } = controller;
  activeController = controller;
  let programmaticScroll = false;
  const scrollTo = () => {
    programmaticScroll = true;
    element.scrollIntoView(options);
  };
  root.addEventListener('contentvisibilityautostatechange', scrollTo, { capture: true, signal });
  window.addEventListener(
    'scroll',
    () => {
      if (programmaticScroll) {
        programmaticScroll = false;
        return;
      }
      controller.abort();
    },
    { capture: true, signal },
  );
  scrollTo();
  return new Promise((resolve) => {
    setTimeout(() => {
      controller.abort();
      activeController = undefined;
      scrollTo();
      resolve();
    }, SETTLE_TIMEOUT);
  });
}
