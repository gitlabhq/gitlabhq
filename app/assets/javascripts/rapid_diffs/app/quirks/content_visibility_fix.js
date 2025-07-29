// content-visibility: auto is very laggy pre Chrome 138
// https://issues.chromium.org/issues/40066846
// text inside content-visibility: auto is not searchable in Safari pre 18.6
// https://bugs.webkit.org/show_bug.cgi?id=283846
export const disableBrokenContentVisibility = (root) => {
  if (/Chrome/.test(navigator.userAgent)) {
    const chromeVersion = parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)[1], 10);
    if (chromeVersion < 138) {
      root.style.setProperty('--rd-content-visibility-auto', 'visible');
    }
  } else if (/Safari/.test(navigator.userAgent)) {
    const [, safariMajor, safariMinor] = (
      navigator.userAgent.match(/\/(\d+)\.(\d+) Safari/) || []
    ).map((num) => parseInt(num, 10));
    if (safariMajor <= 18 && safariMinor <= 5) {
      root.style.setProperty('--rd-content-visibility-auto', 'visible');
    }
  }
};
