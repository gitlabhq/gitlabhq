import initRegistryImages from '~/registry/list/index';
import registryExplorer from '~/registry/explorer/index';

document.addEventListener('DOMContentLoaded', () => {
  initRegistryImages();

  const explorer = registryExplorer();

  if (explorer) {
    explorer.attachBreadcrumb();
    explorer.attachMainComponent();
  }
});
