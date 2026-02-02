import Vue from 'vue';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import { MOUNTED } from '../adapter_events';

export const imageAdapter = {
  [MOUNTED]() {
    const imageData = JSON.parse(
      this.diffElement.querySelector('[data-image-data]').dataset.imageData,
    );
    // eslint-disable-next-line no-new
    new Vue({
      el: this.diffElement.querySelector('[data-image-view]'),
      name: 'ImageViewerRoot',
      render(h) {
        return h(ImageViewer, {
          props: {
            imageData,
          },
        });
      },
    });
  },
};
