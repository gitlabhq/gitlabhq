import registryExplorer from '~/registry/explorer/index';

const explorer = registryExplorer();

if (explorer) {
  explorer.attachBreadcrumb();
  explorer.attachMainComponent();
}
