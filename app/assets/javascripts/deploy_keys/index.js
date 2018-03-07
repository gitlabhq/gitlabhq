import Vue from 'vue';
import deployKeysApp from './components/app.vue';

export default () => new Vue({
  el: document.getElementById('js-deploy-keys'),
  components: {
    deployKeysApp,
  },
  data() {
    return {
      endpoint: this.$options.el.dataset.endpoint,
    };
  },
  render(createElement) {
    return createElement('deploy-keys-app', {
      props: {
        endpoint: this.endpoint,
      },
    });
  },
});
