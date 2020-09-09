/* Wait for.... The methods can be used:
  - with a callback (preferred),
    waitFor(action)

  - with then (discouraged),
    await waitFor().then(action);

  - with await,
    await waitFor;
    action();
*/

const CSS_LOADED_EVENT = 'CSSLoaded';
const DOM_LOADED_EVENT = 'DOMContentLoaded';
const STARTUP_LINK_LOADED_EVENT = 'CSSStartupLinkLoaded';

const isStartupLinkLoaded = ({ dataset }) => dataset.startupcss === 'loaded';

export const handleLoadedEvents = (action = () => {}) => {
  let isCssLoaded = false;
  let eventsList = [CSS_LOADED_EVENT, DOM_LOADED_EVENT];
  return ({ type } = {}) => {
    eventsList = eventsList.filter(e => e !== type);
    if (isCssLoaded) {
      return;
    }
    if (!eventsList.length) {
      isCssLoaded = true;
      action();
    }
  };
};

export const handleStartupEvents = (action = () => {}) => {
  if (!gon.features.startupCss) {
    return action;
  }
  const startupLinks = Array.from(document.querySelectorAll('link[data-startupcss]'));
  return () => {
    if (startupLinks.every(isStartupLinkLoaded)) {
      action();
    }
  };
};

export const waitForStartupLinks = () => {
  let eventListener;
  const promise = new Promise(resolve => {
    eventListener = handleStartupEvents(resolve);
    document.addEventListener(STARTUP_LINK_LOADED_EVENT, eventListener);
  }).then(() => {
    document.dispatchEvent(new CustomEvent(CSS_LOADED_EVENT));
    document.removeEventListener(STARTUP_LINK_LOADED_EVENT, eventListener);
  });
  document.dispatchEvent(new CustomEvent(STARTUP_LINK_LOADED_EVENT));
  return promise;
};

export const waitForCSSLoaded = (action = () => {}) => {
  let eventListener;
  const promise = new Promise(resolve => {
    eventListener = handleLoadedEvents(resolve);
    document.addEventListener(DOM_LOADED_EVENT, eventListener, { once: true });
    document.addEventListener(CSS_LOADED_EVENT, eventListener, { once: true });
  }).then(action);
  waitForStartupLinks();
  return promise;
};
