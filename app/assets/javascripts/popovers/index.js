import { toArray } from 'lodash';
import Vue from 'vue';
import PopoversComponent from './components/popovers.vue';

let app;

const APP_ELEMENT_ID = 'gl-popovers-app';

const getPopoversApp = () => {
  if (!app) {
    const container = document.createElement('div');
    container.setAttribute('id', APP_ELEMENT_ID);
    document.body.appendChild(container);

    const Popovers = Vue.extend(PopoversComponent);
    app = new Popovers({ name: 'PopoversRoot' });
    app.$mount(`#${APP_ELEMENT_ID}`);
  }

  return app;
};

const isPopover = (node, selector) => node.matches && node.matches(selector);

const handlePopoverEvent = (rootTarget, e, selector) => {
  for (let { target } = e; target && target !== rootTarget; target = target.parentNode) {
    if (isPopover(target, selector)) {
      getPopoversApp().addPopovers([target]);
      break;
    }
  }
};

export const initPopovers = () => {
  ['mouseenter', 'focus', 'click'].forEach((event) => {
    document.addEventListener(
      event,
      (e) => handlePopoverEvent(document, e, '[data-toggle="popover"]'),
      true,
    );
  });

  return getPopoversApp();
};

export const dispose = (elements) => toArray(elements).forEach(getPopoversApp().dispose);

export const destroy = () => {
  getPopoversApp().$destroy();
  app = null;
};
