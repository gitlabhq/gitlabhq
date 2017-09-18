import Vue from 'vue';
import imageDiffApp from './components/image_diff_app.vue';

document.querySelectorAll('.js-vue-image-diff').forEach(
  (el) => new Vue({
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
      };
    },
    render(createElement) {
      return createElement('image-diff-app', {
        props: {
          images: this.images,
        },
      });
    },
  }),
);
