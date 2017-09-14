import Vue from 'vue';
import imageDiffApp from './components/image_diff_app.vue';

// TODO: not sure if this is a good idea or not,
// need to instantiate multiple image vue diff
// apps based on number of image diffs

document.querySelectorAll('.js-vue-image-diff').forEach(
  () => new Vue({
    el: '.js-vue-image-diff',
    components: {
      imageDiffApp,
    },
    data() {
      const dataset = document.querySelector('.js-vue-image-diff').dataset;

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
        },
      });
    },
  }),
);
