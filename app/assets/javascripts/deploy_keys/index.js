import Vue from 'vue';
import deployKeysApp from './components/app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: document.getElementById('js-deploy-keys'),
  data() {
    return {
      endpoint: this.$options.el.dataset.endpoint,
    };
  },
  components: {
    deployKeysApp,
  },
  render(createElement) {
    return createElement('deploy-keys-app', {
      props: {
        endpoint: this.endpoint,
      },
    });
  },
}));
