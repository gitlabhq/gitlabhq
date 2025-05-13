// content-visibility was fixed in Chrome 138, older versions are way too laggy with is so we just disable the feature
// https://issues.chromium.org/issues/40066846
export const disableContentVisibilityOnOlderChrome = (root) => {
  if (!/Chrome/.test(navigator.userAgent)) return;
  const chromeVersion = parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)[1], 10);
  if (chromeVersion < 138) {
    root.style.setProperty('--rd-content-visibility-auto', 'visible');
  }
};
