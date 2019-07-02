import Vue from 'vue';
import registryApp from './components/app.vue';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

export default () =>
  new Vue({
    el: '#js-vue-registry-images',
    components: {
      registryApp,
    },
    data() {
      const { dataset } = document.querySelector(this.$options.el);
      return {
        endpoint: dataset.endpoint,
        characterError: Boolean(dataset.characterError),
        helpPagePath: dataset.helpPagePath,
        noContainersImage: dataset.noContainersImage,
        containersErrorImage: dataset.containersErrorImage,
        repositoryUrl: dataset.repositoryUrl,
      };
    },
    render(createElement) {
      return createElement('registry-app', {
        props: {
          endpoint: this.endpoint,
          characterError: this.characterError,
          helpPagePath: this.helpPagePath,
          noContainersImage: this.noContainersImage,
          containersErrorImage: this.containersErrorImage,
          repositoryUrl: this.repositoryUrl,
        },
      });
    },
  });
