import Vue from 'vue';
import ImageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';
import { MOUNTED } from '../events';

export const ImageAdapter = {
  [MOUNTED]() {
    const data = JSON.parse(this.diffElement.querySelector('[data-image-data]').dataset.imageData);
    // eslint-disable-next-line no-new
    new Vue({
      el: this.diffElement.querySelector('[data-image-view]'),
      render(h) {
        return h(ImageDiffViewer, {
          props: {
            oldPath: data.old_path || '',
            newPath: data.new_path || '',
            oldSize: data.old_size ? parseInt(data.old_size, 10) : undefined,
            newSize: data.new_size ? parseInt(data.new_size, 10) : undefined,
            diffMode: data.diff_mode,
            // URLs are already encoded on the backend
            encodePath: false,
          },
        });
      },
    });
  },
};
