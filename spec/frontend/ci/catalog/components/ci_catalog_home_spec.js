import { shallowMount } from '@vue/test-utils';
import { createRouter } from '~/ci/catalog/router';
import ciResourceDetailsPage from '~/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiCatalogHome from '~/ci/catalog/components/ci_catalog_home.vue';

describe('CiCatalogHome', () => {
  const defaultProps = {};
  const baseRoute = '/';
  const resourcesPageComponentStub = {
    name: 'page-component',
    template: '<div>Hello</div>',
  };
  const router = createRouter(baseRoute, resourcesPageComponentStub);

  const createComponent = ({ props = {} } = {}) => {
    shallowMount(CiCatalogHome, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      router,
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('router', () => {
      it.each`
        path         | component
        ${baseRoute} | ${resourcesPageComponentStub}
        ${'/1'}      | ${ciResourceDetailsPage}
      `('when route is $path it renders the right component', async ({ path, component }) => {
        if (path !== '/') {
          await router.push(path);
        }

        const [root] = router.currentRoute.matched;

        expect(root.components.default).toBe(component);
      });
    });
  });
});
