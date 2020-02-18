import initRegistryImages from '~/registry/list/index';
import registryExplorer from '~/registry/explorer/index';

document.addEventListener('DOMContentLoaded', () => {
  initRegistryImages();
  const { attachMainComponent, attachBreadcrumb } = registryExplorer();
  attachBreadcrumb();
  attachMainComponent();
});
