import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import { MOUNTED } from '../adapter_events';

export const imageAdapter = {
  [MOUNTED]() {
    const imageData = JSON.parse(
      this.diffElement.querySelector('[data-image-data]').dataset.imageData,
    );
    initVueApp({
      el: this.diffElement.querySelector('[data-image-view]'),
      name: 'ImageViewerRoot',
      component: ImageViewer,
      props: {
        imageData,
      },
    });
  },
};
