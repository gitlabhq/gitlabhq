import registryExplorer from '~/packages_and_registries/container_registry/explorer/index';

const explorer = registryExplorer();

if (explorer) {
  explorer.attachBreadcrumb();
  explorer.attachMainComponent();
}
