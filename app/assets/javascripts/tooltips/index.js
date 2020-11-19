import Vue from 'vue';
import jQuery from 'jquery';
import { toArray, isFunction, isElement } from 'lodash';
import Tooltips from './components/tooltips.vue';

let app;

const EVENTS_MAP = {
  hover: 'mouseenter',
  click: 'click',
  focus: 'focus',
};

const DEFAULT_TRIGGER = 'hover focus';
const APP_ELEMENT_ID = 'gl-tooltips-app';

const tooltipsApp = () => {
  if (!app) {
    const container = document.createElement('div');

    container.setAttribute('id', APP_ELEMENT_ID);
    document.body.appendChild(container);

    app = new Vue({
      render(h) {
        return h(Tooltips, {
          props: {
            elements: this.elements,
          },
          ref: 'tooltips',
        });
      },
    }).$mount(container);
  }

  return app.$refs.tooltips;
};

const isTooltip = (node, selector) => node.matches && node.matches(selector);

const addTooltips = (elements, config) => {
  tooltipsApp().addTooltips(toArray(elements), config);
};

const handleTooltipEvent = (rootTarget, e, selector, config = {}) => {
  for (let { target } = e; target && target !== rootTarget; target = target.parentNode) {
    if (isTooltip(target, selector)) {
      addTooltips([target], {
        show: true,
        ...config,
      });
      break;
    }
  }
};

const applyToElements = (elements, handler) => {
  const iterable = isElement(elements) ? [elements] : toArray(elements);

  toArray(iterable).forEach(handler);
};

const invokeBootstrapApi = (elements, method) => {
  if (isFunction(elements.tooltip)) {
    elements.tooltip(method);
  } else {
    jQuery(elements).tooltip(method);
  }
};

const isGlTooltipsEnabled = () => Boolean(window.gon.glTooltipsEnabled);

const tooltipApiInvoker = ({ glHandler, bsHandler }) => (elements, ...params) => {
  if (isGlTooltipsEnabled()) {
    applyToElements(elements, glHandler);
  } else {
    bsHandler(elements, ...params);
  }
};

export const initTooltips = (config = {}) => {
  if (isGlTooltipsEnabled()) {
    const triggers = config?.triggers || DEFAULT_TRIGGER;
    const events = triggers.split(' ').map(trigger => EVENTS_MAP[trigger]);

    events.forEach(event => {
      document.addEventListener(
        event,
        e => handleTooltipEvent(document, e, config.selector, config),
        true,
      );
    });

    return tooltipsApp();
  }

  return invokeBootstrapApi(document.body, config);
};
export const add = (elements, config = {}) => {
  if (isGlTooltipsEnabled()) {
    return addTooltips(elements, config);
  }
  return invokeBootstrapApi(elements, config);
};
export const dispose = tooltipApiInvoker({
  glHandler: element => tooltipsApp().dispose(element),
  bsHandler: elements => invokeBootstrapApi(elements, 'dispose'),
});
export const fixTitle = tooltipApiInvoker({
  glHandler: element => tooltipsApp().fixTitle(element),
  bsHandler: elements => invokeBootstrapApi(elements, '_fixTitle'),
});
export const enable = tooltipApiInvoker({
  glHandler: element => tooltipsApp().triggerEvent(element, 'enable'),
  bsHandler: elements => invokeBootstrapApi(elements, 'enable'),
});
export const disable = tooltipApiInvoker({
  glHandler: element => tooltipsApp().triggerEvent(element, 'disable'),
  bsHandler: elements => invokeBootstrapApi(elements, 'disable'),
});
export const hide = tooltipApiInvoker({
  glHandler: element => tooltipsApp().triggerEvent(element, 'close'),
  bsHandler: elements => invokeBootstrapApi(elements, 'hide'),
});
export const show = tooltipApiInvoker({
  glHandler: element => tooltipsApp().triggerEvent(element, 'open'),
  bsHandler: elements => invokeBootstrapApi(elements, 'show'),
});
export const destroy = () => {
  tooltipsApp().$destroy();
  app = null;
};
