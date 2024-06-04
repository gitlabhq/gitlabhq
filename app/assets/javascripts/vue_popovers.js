import Vue from 'vue';
import { GlPopover } from '@gitlab/ui';

const mountVuePopover = (el) => {
  const props = JSON.parse(el.dataset.appData);

  return new Vue({
    el,
    render(createElement) {
      return createElement(GlPopover, {
        props,
        // "target" is a prop in the nested BPopover but is not a prop in GlPopover, so we have to pass down as attrs
        attrs: props,
      });
    },
  });
};

export default () => [...document.querySelectorAll('.js-vue-popover')].map(mountVuePopover);
