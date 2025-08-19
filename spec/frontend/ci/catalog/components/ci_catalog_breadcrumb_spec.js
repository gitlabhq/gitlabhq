import { mount, RouterLinkStub } from '@vue/test-utils';
import CiCatalogBreadcrumb from '~/ci/catalog/components/ci_catalog_breadcrumb.vue';

describe('Ci Catalog Breadcrumb', () => {
  let wrapper;

  const routes = [
    { name: 'ci_resources', path: '/' },
    {
      name: 'ci_resources_details',
      path: '/catalog/root/my-resource',
      params: {
        id: 'root/my-resource',
      },
    },
  ];

  const mountComponent = ($route, props = { staticBreadcrumbs: [] }) => {
    wrapper = mount(CiCatalogBreadcrumb, {
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
      propsData: props,
    });
  };

  describe('when is rootRoute', () => {
    beforeEach(() => {
      mountComponent(routes[0]);
    });

    it('contains only a single router-link to list', () => {
      const links = wrapper.findAllComponents(RouterLinkStub);

      expect(links).toHaveLength(1);
      expect(links.at(0).props('to')).toEqual(routes[0].path);
    });

    it('the link text is correct', () => {
      expect(wrapper.text()).toBe('CI/CD Catalog');
    });
  });

  describe('when is not rootRoute', () => {
    beforeEach(() => {
      mountComponent(routes[1]);
    });

    it('contains two router-links to list and details', () => {
      const links = wrapper.findAllComponents(RouterLinkStub);

      expect(links).toHaveLength(2);
      expect(links.at(0).props('to')).toEqual(routes[0].path);
      expect(links.at(1).props('to')).toBe(routes[1].path);
    });

    it('the last link text is resource path', () => {
      const lastLink = wrapper.findAll('a').at(1);
      expect(lastLink.text()).toContain('my-resource');
    });
  });

  describe('when staticBreadcrumbs are provided', () => {
    beforeEach(() => {
      mountComponent(routes[0], {
        staticBreadcrumbs: [{ text: 'static', href: '/static' }],
      });
    });

    it('contains the static breadcrumbs', () => {
      const links = wrapper.findAll('a');

      expect(links).toHaveLength(2);
      expect(links.at(0).props('href')).toEqual('/static');
      expect(links.at(0).text()).toContain('static');
    });
  });
});
