import registryExplorer from '~/registry/explorer/index';

document.addEventListener('DOMContentLoaded', () => {
  const explorer = registryExplorer();

  if (explorer) {
    explorer.attachBreadcrumb();
    explorer.attachMainComponent();
  }
});
