import Vue from 'vue';
import DeployKeysApp from './components/app.vue';

export default () =>
  new Vue({
    el: document.getElementById('js-deploy-keys'),
    components: {
      DeployKeysApp,
    },
    data() {
      return {
        endpoint: this.$options.el.dataset.endpoint,
        projectId: this.$options.el.dataset.projectId,
      };
    },
    render(createElement) {
      return createElement('deploy-keys-app', {
        props: {
          endpoint: this.endpoint,
          projectId: this.projectId,
        },
      });
    },
  });
