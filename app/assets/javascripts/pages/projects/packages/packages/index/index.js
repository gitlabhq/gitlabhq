(async function packageApp() {
  if (window.gon.features.packageListApollo) {
    const newPackageList = await import('~/packages_and_registries/package_registry/pages/list');

    newPackageList.default();
  } else {
    const packageList = await import('~/packages/list/packages_list_app_bundle');
    packageList.default();
  }
})();
