import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import HarborRegistryBreadcrumb from '~/packages_and_registries/harbor_registry/components/harbor_registry_breadcrumb.vue';

describe('HarborRegistryBreadcrumb', () => {
  let wrapper;

  const findBreadcrumbs = () => wrapper.findComponent(GlBreadcrumb);

  const rootRoute = {
    name: 'root',
    path: '/',
    meta: {
      root: true,
      nameGenerator: () => 'Root',
      hrefGenerator: () => '/',
    },
  };

  const detailsRoute = {
    name: 'details',
    path: '/details',
    meta: {
      nameGenerator: () => 'Details',
      hrefGenerator: () => '/details',
    },
  };

  const createComponent = ({ route, routes, props = {} }) => {
    wrapper = shallowMount(HarborRegistryBreadcrumb, {
      propsData: props,
      mocks: {
        $route: route,
        $router: { options: { routes } },
      },
      stubs: {
        GlBreadcrumb: {
          name: 'GlBreadcrumb',
          props: ['items', 'autoResize'],
          template: '<nav></nav>',
        },
      },
    });
  };

  describe('when mounted', () => {
    it('renders the root breadcrumb when on root route', () => {
      createComponent({
        route: { name: 'root', meta: rootRoute.meta },
        routes: [rootRoute, detailsRoute],
      });
      expect(findBreadcrumbs().props('items')).toStrictEqual([{ text: 'Root', to: '/' }]);
    });

    it('renders both root and current route breadcrumbs when not on root', () => {
      createComponent({
        route: { name: 'details', meta: detailsRoute.meta },
        routes: [rootRoute, detailsRoute],
      });
      expect(findBreadcrumbs().props('items')).toStrictEqual([
        { text: 'Root', to: '/' },
        { text: 'Details', to: '/details' },
      ]);
    });
  });

  describe('when static breadcrumbs are provided', () => {
    it('renders static breadcrumbs along with route breadcrumbs', () => {
      const staticBreadcrumbs = {
        items: [{ text: 'Static Item', href: '/static' }],
      };
      createComponent({
        route: { name: 'details', meta: detailsRoute.meta },
        routes: [rootRoute, detailsRoute],
        props: { staticBreadcrumbs },
      });
      const items = findBreadcrumbs().props('items');
      expect(items[0]).toEqual(staticBreadcrumbs.items[0]);
    });

    it('handles empty static breadcrumbs', () => {
      createComponent({
        route: { name: 'details', meta: detailsRoute.meta },
        routes: [rootRoute, detailsRoute],
        props: { staticBreadcrumbs: { items: [] } },
      });
      expect(findBreadcrumbs().props('items')).toStrictEqual([
        { text: 'Root', to: '/' },
        { text: 'Details', to: '/details' },
      ]);
    });
  });
});
