import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import RegistryBreadcrumb from '~/packages_and_registries/harbor_registry/components/harbor_registry_breadcrumb.vue';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import createRouter from './router';
import HarborRegistryExplorer from './pages/index.vue';

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

export default (id) => {
  const el = document.getElementById(id);

  if (!el) {
    return null;
  }

  const {
    endpoint,
    connectionError,
    invalidPathError,
    isGroupPage,
    noContainersImage,
    containersErrorImage,
    repositoryUrl,
    harborIntegrationProjectName,
    projectName,
  } = el.dataset;

  const breadCrumbState = Vue.observable({
    name: '',
    href: '',
    updateName(value) {
      this.name = value;
    },
    updateHref(value) {
      this.href = value;
    },
  });

  const router = createRouter(endpoint, breadCrumbState);

  const attachMainComponent = () => {
    return new Vue({
      el,
      router,
      provide() {
        return {
          breadCrumbState,
          endpoint,
          connectionError: parseBoolean(connectionError),
          invalidPathError: parseBoolean(invalidPathError),
          isGroupPage: parseBoolean(isGroupPage),
          repositoryUrl,
          harborIntegrationProjectName,
          projectName,
          containersErrorImage,
          noContainersImage,
        };
      },
      render(createElement) {
        return createElement(HarborRegistryExplorer);
      },
    });
  };

  return {
    attachBreadcrumb: () => injectVueAppBreadcrumbs(router, RegistryBreadcrumb),
    attachMainComponent,
  };
};
