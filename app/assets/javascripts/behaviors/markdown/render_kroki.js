import Vue from 'vue';
import DiagramPerformanceWarning from '../components/diagram_performance_warning.vue';
import { unrestrictedPages } from './constants';

/**
 * Create alert element.
 *
 * @param {Element} krokiImage Kroki `img` element
 * @return {Element} Alert element
 */
function createAlert(krokiImage) {
  const app = new Vue({
    el: document.createElement('div'),
    name: 'DiagramPerformanceWarningRoot',
    render(createElement) {
      return createElement(DiagramPerformanceWarning, {
        on: {
          closeAlert() {
            app.$destroy();
            app.$el.remove();
          },
          showImage() {
            krokiImage.removeAttribute('hidden');
            app.$destroy();
            app.$el.remove();
          },
        },
      });
    },
  });

  return app.$el;
}

/**
 * Add warning alert to hidden Kroki images,
 * or show Kroki image if on an unrestricted page.
 *
 * Kroki images are given a hidden attribute by the
 * backend when the original markdown source is large.
 *
 * @param {Array<Element>} krokiImages Array of hidden Kroki `img` elements
 */
export function renderKroki(krokiImages) {
  const pageName = document.querySelector('body').dataset.page;
  const isUnrestrictedPage = unrestrictedPages.includes(pageName);

  krokiImages.forEach((krokiImage) => {
    if (isUnrestrictedPage) {
      krokiImage.removeAttribute('hidden');
      return;
    }

    const parent = krokiImage.parentElement;

    // A single Kroki image is processed multiple times for some reason,
    // so this condition ensures we only create one alert per Kroki image
    if (!Object.prototype.hasOwnProperty.call(parent.dataset, 'krokiProcessed')) {
      parent.dataset.krokiProcessed = 'true';
      parent.after(createAlert(krokiImage));
    }
  });
}
