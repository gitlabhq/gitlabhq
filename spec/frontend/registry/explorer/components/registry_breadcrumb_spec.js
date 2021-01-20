import { mount } from '@vue/test-utils';

import component from '~/registry/explorer/components/registry_breadcrumb.vue';

describe('Registry Breadcrumb', () => {
  let wrapper;
  const nameGenerator = jest.fn();

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
    });
  };

  beforeEach(() => {
    nameGenerator.mockClear();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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
      expect(links.at(0).attributes('href')).toBe('/');
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
      expect(links.at(0).attributes('href')).toBe('/');
      expect(links.at(1).attributes('href')).toBe('#');
    });

    it('the link text is calculated by nameGenerator', () => {
      expect(nameGenerator).toHaveBeenCalledTimes(2);
    });
  });
});
