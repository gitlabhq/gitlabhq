import Vue from 'vue';
import VueApollo from 'vue-apollo';
import apolloProvider from '~/repository/graphql';
import FilePreview from '~/repository/components/preview/index.vue';

Vue.use(VueApollo);

export const initGroupReadme = () => {
  const el = document.getElementById('js-group-readme');

  if (!el) return false;

  const { webPath, name } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(FilePreview, {
        props: {
          blob: { webPath, name },
        },
      });
    },
  });
};
