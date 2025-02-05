import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { provideWebIdeLink } from 'ee_else_ce/pages/projects/shared/web_ide_link/provide_web_ide_link';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import WebIdeButton from 'ee_else_ce/vue_shared/components/web_ide_link.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default ({ el, router }) => {
  if (!el) return;

  const { projectPath, ref, isBlob, webIdeUrl, ...options } = convertObjectPropsToCamelCase(
    JSON.parse(el.dataset.options),
  );
  const { cssClasses, defaultBranch } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      projectPath,
      ...provideWebIdeLink(options),
    },
    render(h) {
      return h(WebIdeButton, {
        props: {
          isBlob,
          webIdeUrl: isBlob
            ? webIdeUrl
            : webIDEUrl(
                joinPaths(
                  '/',
                  projectPath,
                  'edit',
                  ref || defaultBranch,
                  '-',
                  this.$route?.params.path || '',
                  '/',
                ),
              ),
          projectPath,
          cssClasses,
          ...options,
          gitRef: ref,
        },
      });
    },
  });
};
