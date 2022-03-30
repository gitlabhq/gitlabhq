import HarborRegistryExplorer from '~/packages_and_registries/harbor_registry/index';

const explorer = HarborRegistryExplorer('js-harbor-registry-list-group');

if (explorer) {
  explorer.attachBreadcrumb();
  explorer.attachMainComponent();
}
