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
        images: {
          added: dataset.added ? JSON.parse(dataset.added) : null,
          deleted: dataset.deleted ? JSON.parse(dataset.deleted) : null,
        },
        coordinates: JSON.parse(dataset.coordinates),
      };
    },
    render(createElement) {
      return createElement('image-diff-app', {
        props: {
          images: this.images,
          coordinates: this.coordinates,
          uid: index,
        },
      });
    },
  }),
);
