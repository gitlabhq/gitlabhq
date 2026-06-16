import Vue from 'vue';
import { s__ } from '~/locale';
import { pinia } from '~/pinia/instance';
import PackagesListApp from '~/packages_and_registries/infrastructure_registry/list/components/packages_list_app.vue';
import Translate from '~/vue_shared/translate';
import { GROUP_PAGE_TYPE } from '~/packages_and_registries/infrastructure_registry/list/constants';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');

  const { pageType, resourceId, emptyListIllustration } = el.dataset;
  const isGroupPage = pageType === GROUP_PAGE_TYPE;

  return new Vue({
    el,
    name: 'PackagesListAppRoot',
    pinia,
    components: {
      PackagesListApp,
    },
    provide: {
      isGroupPage,
      resourceId,
      emptyListIllustration,
      noResultsText: s__(
        'InfrastructureRegistry|Terraform modules are the main way to package and reuse resource configurations with Terraform. Learn more about how to %{noPackagesLinkStart}create Terraform modules%{noPackagesLinkEnd} in GitLab.',
      ),
    },
    render(createElement) {
      return createElement('packages-list-app');
    },
  });
};
