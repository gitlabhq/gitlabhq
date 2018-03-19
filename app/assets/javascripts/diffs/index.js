import Vue from 'vue';
import diffsApp from './components/app.vue';

document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
      el: '#js-diffs-app',
      components: {
        diffsApp,
      },
      data() {
        const dataset = document.querySelector(this.$options.el).dataset;

        return {
          endpoint: dataset.path,
        };
      },
      render(createElement) {
        return createElement('diffs-app', {
          props: {
            endpoint: this.endpoint,
          },
        });
      },
    }),
);
