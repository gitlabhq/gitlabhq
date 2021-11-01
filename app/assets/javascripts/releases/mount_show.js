import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ReleaseShowApp from './components/app_show.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('js-show-release-page');

  if (!el) return false;

  const { projectPath, tagName } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      fullPath: projectPath,
      tagName,
    },
    render: (h) => h(ReleaseShowApp),
  });
};
