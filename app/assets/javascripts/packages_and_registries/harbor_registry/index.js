import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import RegistryBreadcrumb from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';
import { renderBreadcrumb } from '~/packages_and_registries/shared/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  dockerBuildCommand,
  dockerPushCommand,
  dockerLoginCommand,
} from '~/packages_and_registries/harbor_registry/constants';
import createRouter from './router';
import HarborRegistryExplorer from './pages/index.vue';

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

export default (id) => {
  const el = document.getElementById(id);

  if (!el) {
    return null;
  }

  const { endpoint, connectionError, invalidPathError, isGroupPage, ...config } = el.dataset;

  const breadCrumbState = Vue.observable({
    name: '',
    updateName(value) {
      this.name = value;
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
          config: {
            ...config,
            connectionError: parseBoolean(connectionError),
            invalidPathError: parseBoolean(invalidPathError),
            isGroupPage: parseBoolean(isGroupPage),
            helpPagePath: helpPagePath('user/packages/container_registry/index'),
          },
          dockerBuildCommand: dockerBuildCommand(config.repositoryUrl),
          dockerPushCommand: dockerPushCommand(config.repositoryUrl),
          dockerLoginCommand: dockerLoginCommand(config.registryHostUrlWithPort),
        };
      },
      render(createElement) {
        return createElement(HarborRegistryExplorer);
      },
    });
  };

  return {
    attachBreadcrumb: renderBreadcrumb(router, null, RegistryBreadcrumb),
    attachMainComponent,
  };
};
