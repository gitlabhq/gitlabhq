import packageApp from '~/packages_and_registries/package_registry/index';

const app = packageApp();

if (app) {
  app.attachBreadcrumb();
  app.attachMainComponent();
}
