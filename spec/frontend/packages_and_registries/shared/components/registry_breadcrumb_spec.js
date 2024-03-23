import { mount, RouterLinkStub } from '@vue/test-utils';

import component from '~/packages_and_registries/shared/components/registry_breadcrumb.vue';

describe('Registry Breadcrumb', () => {
  let wrapper;
  const nameGenerator = jest.fn().mockImplementation(() => {
    // return a non-empty name, otherwise item validations could fail.
    return 'mock name';
  });

  const routes = [
    { name: 'list', path: '/', meta: { nameGenerator, root: true } },
    { name: 'details', path: '/:id', meta: { nameGenerator } },
  ];

  const mountComponent = ($route) => {
    wrapper = mount(component, {
      mocks: {
        $route,
        $router: {
          options: {
            routes,
          },
        },
      },
      stubs: {
        RouterLink: RouterLinkStub,
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

    it('renders', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains only a single router-link to list', () => {
      const links = wrapper.findAll('a');

      expect(links).toHaveLength(1);
    });

    it('the link text is calculated by nameGenerator', () => {
      expect(nameGenerator).toHaveBeenCalledTimes(1);
    });
  });

  describe('when is not rootRoute', () => {
    beforeEach(() => {
      mountComponent(routes[1]);
    });

    it('renders', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains two router-links to list and details', () => {
      const links = wrapper.findAll('a');

      expect(links).toHaveLength(2);
      expect(links.at(1).attributes('href')).toBe('#');
    });

    it('the link text is calculated by nameGenerator', () => {
      expect(nameGenerator).toHaveBeenCalledTimes(2);
    });
  });
});
