import Vue from 'vue';
import imageDiffApp from './components/image_diff_app.vue';

document.querySelectorAll('.js-vue-image-diff').forEach(
  (el, index) => new Vue({
    el,
    components: {
      imageDiffApp,
    },
    data() {
      const dataset = el.dataset;

      return {
        initialImages: {
          added: dataset.added ? JSON.parse(dataset.added) : null,
          deleted: dataset.deleted ? JSON.parse(dataset.deleted) : null,
        },
        initialCoordinates: JSON.parse(dataset.coordinates),
      };
    },
    render(createElement) {
      return createElement('image-diff-app', {
        props: {
          initialImages: this.initialImages,
          initialCoordinates: this.initialCoordinates,
          uid: index,
        },
      });
    },
  }),
);
