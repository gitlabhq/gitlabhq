import Vue from 'vue';
import registryApp from './components/app.vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-registry-images');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    components: {
      registryApp,
    },
    data() {
      const { dataset } = el;
      return {
        registryData: {
          endpoint: dataset.endpoint,
          characterError: Boolean(dataset.characterError),
          helpPagePath: dataset.helpPagePath,
          noContainersImage: dataset.noContainersImage,
          containersErrorImage: dataset.containersErrorImage,
          repositoryUrl: dataset.repositoryUrl,
          isGroupPage: dataset.isGroupPage,
          personalAccessTokensHelpLink: dataset.personalAccessTokensHelpLink,
          registryHostUrlWithPort: dataset.registryHostUrlWithPort,
          twoFactorAuthHelpLink: dataset.twoFactorAuthHelpLink,
        },
      };
    },
    render(createElement) {
      return createElement('registry-app', {
        props: {
          ...this.registryData,
        },
      });
    },
  });
};
