import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import JhTransitionBanner from './components/jh_transition_banner.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initJHTransitionBanner = () => {
  const el = document.querySelector('.js-jh-transition-banner');

  if (!el) return false;

  const { featureName, userPreferredLanguage } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(JhTransitionBanner, {
        props: {
          featureName,
          userPreferredLanguage,
        },
      });
    },
  });
};
