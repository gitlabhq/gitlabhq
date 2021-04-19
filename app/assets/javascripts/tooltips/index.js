import { toArray, isElement } from 'lodash';
import Vue from 'vue';
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
      addTooltips([target], config);
      break;
    }
  }
};

const applyToElements = (elements, handler) => {
  const iterable = isElement(elements) ? [elements] : toArray(elements);

  toArray(iterable).forEach(handler);
};

const createTooltipApiInvoker = (glHandler) => (elements) => {
  applyToElements(elements, glHandler);
};

export const initTooltips = (config = {}) => {
  const triggers = config?.triggers || DEFAULT_TRIGGER;
  const events = triggers.split(' ').map((trigger) => EVENTS_MAP[trigger]);

  events.forEach((event) => {
    document.addEventListener(
      event,
      (e) => handleTooltipEvent(document, e, config.selector, config),
      true,
    );
  });

  return tooltipsApp();
};
export const add = (elements, config = {}) => addTooltips(elements, config);
export const dispose = createTooltipApiInvoker((element) => tooltipsApp().dispose(element));
export const fixTitle = createTooltipApiInvoker((element) => tooltipsApp().fixTitle(element));
export const enable = createTooltipApiInvoker((element) =>
  tooltipsApp().triggerEvent(element, 'enable'),
);
export const disable = createTooltipApiInvoker((element) =>
  tooltipsApp().triggerEvent(element, 'disable'),
);
export const hide = createTooltipApiInvoker((element) =>
  tooltipsApp().triggerEvent(element, 'close'),
);
export const show = createTooltipApiInvoker((element) =>
  tooltipsApp().triggerEvent(element, 'open'),
);
export const once = (event, cb) => tooltipsApp().$once(event, cb);
export const destroy = () => {
  tooltipsApp().$destroy();
  app = null;
};
