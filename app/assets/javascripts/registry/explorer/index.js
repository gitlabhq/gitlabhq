import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import RegistryBreadcrumb from './components/registry_breadcrumb.vue';
import { apolloProvider } from './graphql/index';
import RegistryExplorer from './pages/index.vue';
import createRouter from './router';

Vue.use(Translate);
Vue.use(GlToast);

Vue.use(PerformancePlugin, {
  components: [
    'RegistryListPage',
    'ListHeader',
    'ImageListRow',
    'RegistryDetailsPage',
    'DetailsHeader',
    'TagsList',
  ],
});

export default () => {
  const el = document.getElementById('js-container-registry');

  if (!el) {
    return null;
  }

  const {
    endpoint,
    expirationPolicy,
    isGroupPage,
    isAdmin,
    showCleanupPolicyOnAlert,
    showUnfinishedTagCleanupCallout,
    ...config
  } = el.dataset;

  // This is a mini state to help the breadcrumb have the correct name in the details page
  const breadCrumbState = Vue.observable({
    name: '',
    updateName(value) {
      this.name = value;
    },
  });

  const router = createRouter(endpoint, breadCrumbState);

  const attachMainComponent = () =>
    new Vue({
      el,
      router,
      apolloProvider,
      components: {
        RegistryExplorer,
      },
      provide() {
        return {
          breadCrumbState,
          config: {
            ...config,
            expirationPolicy: expirationPolicy ? JSON.parse(expirationPolicy) : undefined,
            isGroupPage: parseBoolean(isGroupPage),
            isAdmin: parseBoolean(isAdmin),
            showCleanupPolicyOnAlert: parseBoolean(showCleanupPolicyOnAlert),
            showUnfinishedTagCleanupCallout: parseBoolean(showUnfinishedTagCleanupCallout),
          },
          /* eslint-disable @gitlab/require-i18n-strings */
          dockerBuildCommand: `docker build -t ${config.repositoryUrl} .`,
          dockerPushCommand: `docker push ${config.repositoryUrl}`,
          dockerLoginCommand: `docker login ${config.registryHostUrlWithPort}`,
          /* eslint-enable @gitlab/require-i18n-strings */
        };
      },
      render(createElement) {
        return createElement('registry-explorer');
      },
    });

  const attachBreadcrumb = () => {
    const breadCrumbEls = document.querySelectorAll('nav .js-breadcrumbs-list li');
    const breadCrumbEl = breadCrumbEls[breadCrumbEls.length - 1];
    const crumbs = [breadCrumbEl.querySelector('h2')];
    const nestedBreadcrumbEl = document.createElement('div');
    breadCrumbEl.replaceChild(nestedBreadcrumbEl, breadCrumbEl.querySelector('h2'));
    return new Vue({
      el: nestedBreadcrumbEl,
      router,
      apolloProvider,
      components: {
        RegistryBreadcrumb,
      },
      render(createElement) {
        // FIXME(@tnir): this is a workaround until the MR gets merged:
        // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48115
        const parentEl = breadCrumbEl.parentElement.parentElement;
        if (parentEl) {
          parentEl.classList.remove('breadcrumbs-container');
          parentEl.classList.add('gl-display-flex');
          parentEl.classList.add('w-100');
        }
        // End of FIXME(@tnir)
        return createElement('registry-breadcrumb', {
          class: breadCrumbEl.className,
          props: {
            crumbs,
          },
        });
      },
    });
  };

  return { attachBreadcrumb, attachMainComponent };
};
