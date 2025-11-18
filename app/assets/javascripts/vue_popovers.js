import Vue from 'vue';
import { GlPopover } from '@gitlab/ui';

const mountVuePopover = (el) => {
  const props = JSON.parse(el.dataset.appData);

  const instance = new Vue({
    render(createElement) {
      return createElement(GlPopover, {
        attrs: props,
      });
    },
  });

  // Vue 2 replaces the mounting target (targetEl) with the component’s rendered DOM.
  // It literally removes the mounting <div> and inserts the rendered root element in its place.
  // In Vue 3, the mount(el) does not replace the mounting element.
  // It renders the component inside that element.
  // This approach would make it work both for Vue 2 and Vue 3
  const mountElement = document.createElement('div');
  el.replaceWith(mountElement);
  instance.$mount(mountElement);

  return instance;
};

export default () => [...document.querySelectorAll('.js-vue-popover')].map(mountVuePopover);
