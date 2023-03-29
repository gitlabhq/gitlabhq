import Vue from 'vue';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

export function getFrameSrc(url) {
  return `${setUrlParams({ theme: darkModeEnabled() ? 'dark' : 'light' }, url)}&kiosk`;
}

const mountVueComponent = (element) => {
  const url = [element.dataset.frameUrl];

  return new Vue({
    el: element,
    render(h) {
      return h('iframe', {
        style: {
          height: '366px',
          width: '768px',
        },
        attrs: {
          src: getFrameSrc(url),
          frameBorder: '0',
        },
      });
    },
  });
};

export default function renderObservability(elements) {
  elements.forEach((element) => {
    mountVueComponent(element);
  });
}
