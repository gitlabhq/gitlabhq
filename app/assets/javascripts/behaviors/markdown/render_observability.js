import Vue from 'vue';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

export function getFrameSrc(url) {
  return `${setUrlParams({ theme: darkModeEnabled() ? 'dark' : 'light' }, url)}&kiosk`;
}

const mountVueComponent = (element) => {
  const { frameUrl, observabilityUrl } = element.dataset;

  try {
    if (
      !observabilityUrl ||
      !frameUrl ||
      new URL(frameUrl)?.host !== new URL(observabilityUrl).host
    )
      return;

    // eslint-disable-next-line no-new
    new Vue({
      el: element,
      render(h) {
        return h('iframe', {
          style: {
            height: '366px',
            width: '768px',
          },
          attrs: {
            src: getFrameSrc(frameUrl),
            frameBorder: '0',
          },
        });
      },
    });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }
};

export default function renderObservability(elements) {
  elements.forEach((element) => {
    mountVueComponent(element);
  });
}
