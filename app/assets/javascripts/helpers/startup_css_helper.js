const CSS_LOADED_EVENT = 'CSSLoaded';
const STARTUP_LINK_LOADED_EVENT = 'CSSStartupLinkLoaded';

const getAllStartupLinks = (() => {
  let links = null;
  return () => {
    if (!links) {
      links = Array.from(document.querySelectorAll('link[data-startupcss]'));
    }
    return links;
  };
})();
const isStartupLinkLoaded = ({ dataset }) => dataset.startupcss === 'loaded';
const allLinksLoaded = () => getAllStartupLinks().every(isStartupLinkLoaded);

const handleStartupEvents = () => {
  if (allLinksLoaded()) {
    document.dispatchEvent(new CustomEvent(CSS_LOADED_EVENT));
    document.removeEventListener(STARTUP_LINK_LOADED_EVENT, handleStartupEvents);
  }
};

/* For `waitForCSSLoaded` methods, see docs.gitlab.com/ee/development/fe_guide/performance.html#important-considerations */
export const waitForCSSLoaded = (action = () => {}) => {
  if (!gon?.features?.startupCss || allLinksLoaded()) {
    return new Promise(resolve => {
      action();
      resolve();
    });
  }

  return new Promise(resolve => {
    document.addEventListener(CSS_LOADED_EVENT, resolve, { once: true });
    document.addEventListener(STARTUP_LINK_LOADED_EVENT, handleStartupEvents);
  }).then(action);
};
