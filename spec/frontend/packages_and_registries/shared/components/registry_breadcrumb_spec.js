import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';

import component from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';

describe('Registry Breadcrumb', () => {
  let wrapper;
  const nameGenerator = jest.fn().mockImplementation(() => {
    // return a non-empty name, otherwise item validations could fail.
    return 'mock name';
  });

  const defaultRoutes = [
    { name: 'list', path: '/', meta: { nameGenerator, root: true } },
    { name: 'details', path: '/:id', params: { id: '1' } },
  ];

  const routesWithNameGenerator = [
    { name: 'list', path: '/', meta: { nameGenerator, root: true } },
    {
      name: 'details',
      path: '/:id',
      params: { id: '1' },
      meta: { nameGenerator },
    },
  ];

  const mountComponent = ({ $route, props = {}, routes = defaultRoutes } = {}) => {
    wrapper = shallowMount(component, {
      propsData: { staticBreadcrumbs: [], ...props },
      mocks: {
        $route,
        $router: {
          options: {
            routes,
          },
        },
      },
    });
  };

  beforeEach(() => {
    nameGenerator.mockClear();
  });

  describe('when is rootRoute', () => {
    beforeEach(() => {
      mountComponent({ $route: defaultRoutes[0] });
    });

    it('only passes root to `items` prop', () => {
      expect(wrapper.findComponent(GlBreadcrumb).props('items')).toEqual([
        {
          text: 'mock name',
          to: '/',
        },
      ]);
    });
  });

  describe('when is not rootRoute', () => {
    beforeEach(() => {
      mountComponent({ $route: defaultRoutes[1] });
    });

    it('passes root and details to `items` prop', () => {
      const breadcrumbItems = wrapper.findComponent(GlBreadcrumb).props('items');
      expect(breadcrumbItems).toHaveLength(2);
      expect(breadcrumbItems).toEqual([
        {
          text: 'mock name',
          to: '/',
        },
        {
          text: '1',
          to: { name: 'details', params: defaultRoutes[1].params },
        },
      ]);
    });
  });

  describe('when is not rootRoute and has meta.nameGenerator', () => {
    beforeEach(() => {
      mountComponent({ $route: routesWithNameGenerator[1], routes: routesWithNameGenerator });
    });

    it('passes root and details to `items` prop', () => {
      const breadcrumbItems = wrapper.findComponent(GlBreadcrumb).props('items');
      expect(breadcrumbItems).toHaveLength(2);
      expect(breadcrumbItems).toEqual([
        {
          text: 'mock name',
          to: '/',
        },
        {
          text: 'mock name',
          to: { name: 'details', params: defaultRoutes[1].params },
        },
      ]);
    });
  });

  it('passes static breadcrumbs along with route breadcrumbs', () => {
    mountComponent({
      $route: defaultRoutes[1],
      props: { staticBreadcrumbs: [{ text: 'Static', href: '/static' }] },
    });
    const breadcrumbItems = wrapper.findComponent(GlBreadcrumb).props('items');
    expect(breadcrumbItems).toHaveLength(3);
    expect(breadcrumbItems[0]).toEqual({ text: 'Static', href: '/static' });
  });
});
