import { mount, RouterLinkStub } from '@vue/test-utils';

import EnvironmentBreadcrumb from '~/environments/environment_details/environment_breadcrumbs.vue';

describe('Environment Breadcrumb', () => {
  let wrapper;
  const environmentName = 'production';

  const routes = [
    { name: 'environment_details', path: '/', meta: { environmentName } },
    {
      name: 'logs',
      path: '/k8s/namespace/namespace/pods/podName/logs',
      meta: { environmentName },
      params: {
        namespace: 'namespace',
        podName: 'podName',
      },
    },
  ];

  const mountComponent = ($route) => {
    wrapper = mount(EnvironmentBreadcrumb, {
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

  describe('when is rootRoute', () => {
    beforeEach(() => {
      mountComponent(routes[0]);
    });

    it('contains only a single router-link to list', () => {
      const links = wrapper.findAll('a');

      expect(links).toHaveLength(1);
      expect(links.at(0).props('to')).toEqual(routes[0].path);
    });

    it('the link text is environmentName', () => {
      expect(wrapper.text()).toContain(environmentName);
    });
  });

  describe('when is not rootRoute', () => {
    beforeEach(() => {
      mountComponent(routes[1]);
    });

    it('contains two router-links to list and details', () => {
      const links = wrapper.findAll('a');

      expect(links).toHaveLength(2);
      expect(links.at(0).props('to')).toEqual(routes[0].path);
      expect(links.at(1).props('to')).toBe(routes[1].path);
    });

    it('the last link text is podName', () => {
      const lastLink = wrapper.findAll('a').at(1);
      expect(lastLink.text()).toContain(routes[1].params.podName);
    });
  });
});
