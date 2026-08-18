// content-visibility: auto is very laggy pre Chrome 138
// https://issues.chromium.org/issues/40066846
// revealed content keeps stale zero-height layout in Safari
// https://bugs.webkit.org/show_bug.cgi?id=321501
// scrolling content-visibility: auto is far more expensive in Safari than in Chrome
// https://bugs.webkit.org/show_bug.cgi?id=318216
// text inside content-visibility: auto is not searchable in Safari pre 18.6
// https://bugs.webkit.org/show_bug.cgi?id=283846
export const disableBrokenContentVisibility = (root) => {
  if (/Chrome/.test(navigator.userAgent)) {
    const chromeVersion = parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)[1], 10);
    if (chromeVersion < 138) {
      root.style.setProperty('--rd-content-visibility-auto', 'visible');
    }
    // Chrome's user agent contains "Safari" as well
  } else if (/Safari/.test(navigator.userAgent)) {
    root.style.setProperty('--rd-content-visibility-auto', 'visible');
  }
};
