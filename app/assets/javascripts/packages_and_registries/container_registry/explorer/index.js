import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import RegistryBreadcrumb from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { apolloProvider } from 'ee_else_ce/packages_and_registries/container_registry/explorer/graphql';
import RegistryExplorer from './pages/index.vue';
import createRouter from './router';

Vue.use(Translate);

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
    isMetadataDatabaseEnabled,
    showCleanupPolicyLink,
    showContainerRegistrySettings,
    showUnfinishedTagCleanupCallout,
    connectionError,
    invalidPathError,
    securityConfigurationPath,
    vulnerabilityReportPath,
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
            showCleanupPolicyLink: parseBoolean(showCleanupPolicyLink),
            showContainerRegistrySettings: parseBoolean(showContainerRegistrySettings),
            showUnfinishedTagCleanupCallout: parseBoolean(showUnfinishedTagCleanupCallout),
            connectionError: parseBoolean(connectionError),
            invalidPathError: parseBoolean(invalidPathError),
            isMetadataDatabaseEnabled: parseBoolean(isMetadataDatabaseEnabled),
            securityConfigurationPath,
            vulnerabilityReportPath,
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

  return {
    attachBreadcrumb: () => injectVueAppBreadcrumbs(router, RegistryBreadcrumb, apolloProvider),
    attachMainComponent,
  };
};
