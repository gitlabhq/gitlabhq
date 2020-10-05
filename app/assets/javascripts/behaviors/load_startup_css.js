export const loadStartupCSS = () => {
  // We need to fallback to dispatching `load` in case our event listener was added too late
  // or the browser environment doesn't load media=print.
  // Do this on `window.load` so that the default deferred behavior takes precedence.
  // https://gitlab.com/gitlab-org/gitlab/-/issues/239357
  window.addEventListener(
    'load',
    () => {
      document
        .querySelectorAll('link[media=print]')
        .forEach(x => x.dispatchEvent(new Event('load')));
    },
    { once: true },
  );
};
