function isOpera(userAgent) {
  return userAgent.indexOf('Opera') >= 0 || userAgent.indexOf('OPR') >= 0;
}

function getOperaVersion(userAgent) {
  const match = userAgent.match(/OPR[^0-9]*([0-9]+)[^0-9]+/);
  return match ? parseInt(match[1], 10) : false;
}

function isChrome(userAgent) {
  return userAgent.indexOf('Chrom') >= 0 && !isOpera(userAgent);
}

function getChromeVersion(userAgent) {
  const match = userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\./);
  return match ? parseInt(match[1], 10) : false;
}

export function canInjectU2fApi(userAgent) {
  const isSupportedChrome = isChrome(userAgent) && getChromeVersion(userAgent) >= 41;
  const isSupportedOpera = isOpera(userAgent) && getOperaVersion(userAgent) >= 40;
  const isMobile = (
    userAgent.indexOf('droid') >= 0 ||
    userAgent.indexOf('CriOS') >= 0 ||
    /\b(iPad|iPhone|iPod)(?=;)/.test(userAgent)
  );
  return (isSupportedChrome || isSupportedOpera) && !isMobile;
}

export default function importU2FLibrary() {
  if (window.u2f) {
    return Promise.resolve(window.u2f);
  }

  const userAgent = typeof navigator !== 'undefined' ? navigator.userAgent : '';
  if (canInjectU2fApi(userAgent) || (gon && gon.test_env)) {
    return import(/* webpackMode: "eager" */ 'vendor/u2f').then(() => window.u2f);
  }

  return Promise.reject();
}
