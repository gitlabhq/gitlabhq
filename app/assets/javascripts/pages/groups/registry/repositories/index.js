import initRegistryImages from '~/registry/list/index';
import registryExplorer from '~/registry/explorer/index';

document.addEventListener('DOMContentLoaded', () => {
  initRegistryImages();
  registryExplorer();
});
