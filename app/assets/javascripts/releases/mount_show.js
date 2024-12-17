import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ReleaseShowApp from './components/app_show.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('js-show-release-page');

  if (!el) return false;

  const { projectPath, tagName, deployments } = el.dataset;

  let parsedDeployments;

  try {
    parsedDeployments = JSON.parse(deployments);
  } catch {
    parsedDeployments = {};
  }

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      tagName,
    },
    render: (h) =>
      h(ReleaseShowApp, {
        props: {
          deployments: convertObjectPropsToCamelCase(parsedDeployments, { deep: true }),
        },
      }),
  });
};
