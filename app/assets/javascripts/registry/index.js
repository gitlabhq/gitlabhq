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
        characterError: Boolean(dataset.characterError),
        containersErrorImage: dataset.containersErrorImage,
        endpoint: dataset.endpoint,
        helpPagePath: dataset.helpPagePath,
        noContainersImage: dataset.noContainersImage,
        personalAccessTokensHelpLink: dataset.personalAccessTokensHelpLink,
        registryHostUrlWithPort: dataset.registryHostUrlWithPort,
        repositoryUrl: dataset.repositoryUrl,
        twoFactorAuthHelpLink: dataset.twoFactorAuthHelpLink,
      };
    },
    render(createElement) {
      return createElement('registry-app', {
        props: {
          characterError: this.characterError,
          containersErrorImage: this.containersErrorImage,
          endpoint: this.endpoint,
          helpPagePath: this.helpPagePath,
          noContainersImage: this.noContainersImage,
          personalAccessTokensHelpLink: this.personalAccessTokensHelpLink,
          registryHostUrlWithPort: this.registryHostUrlWithPort,
          repositoryUrl: this.repositoryUrl,
          twoFactorAuthHelpLink: this.twoFactorAuthHelpLink,
        },
      });
    },
  });
