(async function initPackage() {
  let app;
  if (document.getElementById('js-vue-packages-detail-new')) {
    app = await import(
      /* webpackChunkName: 'new_package_app' */ `~/packages_and_registries/package_registry/pages/details.js`
    );
  } else {
    app = await import('~/packages/details/');
  }
  app.default();
})();
