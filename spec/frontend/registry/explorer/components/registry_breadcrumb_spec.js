import { shallowMount } from '@vue/test-utils';

import component from '~/registry/explorer/components/registry_breadcrumb.vue';

describe('Registry Breadcrumb', () => {
  let wrapper;
  const nameGenerator = jest.fn();

  const crumb = {
    className: 'foo bar',
    tagName: 'div',
    innerHTML: 'baz',
    querySelector: jest.fn(),
    children: [
      {
        tagName: 'a',
        className: 'foo',
      },
    ],
  };

  const querySelectorReturnValue = {
    classList: ['js-divider'],
    tagName: 'svg',
    innerHTML: 'foo',
  };

  const crumbs = [crumb, { ...crumb, innerHTML: 'foo' }, { ...crumb, className: 'baz' }];

  const routes = [
    { name: 'foo', meta: { nameGenerator, root: true } },
    { name: 'baz', meta: { nameGenerator } },
  ];

  const state = {
    imageDetails: { foo: 'bar' },
  };

  const findDivider = () => wrapper.find('.js-divider');
  const findRootRoute = () => wrapper.find({ ref: 'rootRouteLink' });
  const findChildRoute = () => wrapper.find({ ref: 'childRouteLink' });
  const findLastCrumb = () => wrapper.find({ ref: 'lastCrumb' });

  const mountComponent = $route => {
    wrapper = shallowMount(component, {
      propsData: {
        crumbs,
      },
      stubs: {
        'router-link': { name: 'router-link', template: '<a><slot></slot></a>', props: ['to'] },
      },
      mocks: {
        $route,
        $router: {
          options: {
            routes,
          },
        },
        $store: {
          state,
        },
      },
    });
  };

  beforeEach(() => {
    nameGenerator.mockClear();
    crumb.querySelector = jest.fn();
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

    it('contains a router-link for the child route', () => {
      expect(findChildRoute().exists()).toBe(true);
    });

    it('the link text is calculated by nameGenerator', () => {
      expect(nameGenerator).toHaveBeenCalledWith(state);
      expect(nameGenerator).toHaveBeenCalledTimes(1);
    });
  });

  describe('when is not rootRoute', () => {
    beforeEach(() => {
      crumb.querySelector.mockReturnValue(querySelectorReturnValue);
      mountComponent(routes[1]);
    });

    it('renders a divider', () => {
      expect(findDivider().exists()).toBe(true);
    });

    it('contains a router-link for the root route', () => {
      expect(findRootRoute().exists()).toBe(true);
    });

    it('contains a router-link for the child route', () => {
      expect(findChildRoute().exists()).toBe(true);
    });

    it('the link text is calculated by nameGenerator', () => {
      expect(nameGenerator).toHaveBeenCalledWith(state);
      expect(nameGenerator).toHaveBeenCalledTimes(2);
    });
  });

  describe('last crumb', () => {
    const lastChildren = crumb.children[0];
    beforeEach(() => {
      nameGenerator.mockReturnValue('foo');
      mountComponent(routes[0]);
    });

    it('has the same tag as the last children of the crumbs', () => {
      expect(findLastCrumb().element.tagName).toBe(lastChildren.tagName.toUpperCase());
    });

    it('has the same classes as the last children of the crumbs', () => {
      expect(
        findLastCrumb()
          .classes()
          .join(' '),
      ).toEqual(lastChildren.className);
    });

    it('has a link to the current route', () => {
      expect(findChildRoute().props('to')).toEqual({ to: routes[0].name });
    });

    it('the link has the correct text', () => {
      expect(findChildRoute().text()).toEqual('foo');
    });
  });
});
