import Vue from 'vue';
import { toArray } from 'lodash';
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

export const initTooltips = (selector, config = {}) => {
  const triggers = config?.triggers || DEFAULT_TRIGGER;
  const events = triggers.split(' ').map(trigger => EVENTS_MAP[trigger]);

  events.forEach(event => {
    document.addEventListener(event, e => handleTooltipEvent(document, e, selector, config), true);
  });

  return tooltipsApp();
};

const elementsIterator = handler => elements => toArray(elements).forEach(handler);

export const dispose = elementsIterator(element => tooltipsApp().dispose(element));
export const fixTitle = elementsIterator(element => tooltipsApp().fixTitle(element));
export const enable = elementsIterator(element => tooltipsApp().triggerEvent(element, 'enable'));
export const disable = elementsIterator(element => tooltipsApp().triggerEvent(element, 'disable'));
export const hide = elementsIterator(element => tooltipsApp().triggerEvent(element, 'close'));
export const show = elementsIterator(element => tooltipsApp().triggerEvent(element, 'open'));

export const destroy = () => {
  tooltipsApp().$destroy();
  app = null;
};
