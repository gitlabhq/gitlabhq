import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';

import component from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';

describe('Registry Breadcrumb', () => {
  let wrapper;
  const nameGenerator = jest.fn().mockImplementation(() => {
    // return a non-empty name, otherwise item validations could fail.
    return 'mock name';
  });

  const routes = [
    { name: 'list', path: '/', meta: { nameGenerator, root: true } },
    { name: 'details', path: '/:id', meta: { nameGenerator, path: '/details' } },
  ];

  const mountComponent = ($route) => {
    wrapper = shallowMount(component, {
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
      mountComponent(routes[0]);
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
      mountComponent(routes[1]);
    });

    it('passes root and details to `items` prop', () => {
      expect(wrapper.findComponent(GlBreadcrumb).props('items')).toEqual([
        {
          text: 'mock name',
          to: '/',
        },
        {
          text: 'mock name',
          href: '/details',
        },
      ]);
    });
  });
});
