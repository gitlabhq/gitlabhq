import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import SpaBreadcrumbs from '~/vue_shared/spa/components/spa_breadcrumbs.vue';

describe('SpaBreadcrumbs', () => {
  let wrapper;

  const findGlBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const createWrapper = (props = {}, routeData = {}) => {
    const defaultProps = {
      allStaticBreadcrumbs: [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
      ],
    };

    const defaultRoute = {
      params: {},
      matched: [],
    };

    wrapper = shallowMount(SpaBreadcrumbs, {
      propsData: { ...defaultProps, ...props },
      mocks: {
        $route: { ...defaultRoute, ...routeData },
      },
      stubs: {
        GlBreadcrumb: true,
      },
    });
  };

  describe('when only static breadcrumbs are provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders GlBreadcrumb component', () => {
      expect(findGlBreadcrumb().exists()).toBe(true);
    });

    it('passes static breadcrumbs to GlBreadcrumb', () => {
      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });

    it('sets auto-resize to false', () => {
      expect(findGlBreadcrumb().props('autoResize')).toBe(false);
    });
  });

  describe('when route has matched routes with meta', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          matched: [
            {
              name: 'projects',
              path: '/projects',
              meta: { text: 'All Projects' },
            },
            {
              name: 'project-detail',
              path: '/projects/:id',
              meta: { text: 'Project Details' },
              parent: true,
            },
          ],
        },
      );
    });

    it('includes route breadcrumbs with meta text', () => {
      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
        { text: 'All Projects', to: { path: '/projects' } },
        { text: 'Project Details', to: { name: 'project-detail' } },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });
  });

  describe('when route has matched routes without meta', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          params: { id: '123' },
          matched: [
            {
              name: 'project-detail',
              path: '/projects/:id',
              parent: true,
            },
          ],
        },
      );
    });

    it('uses route param id as breadcrumb text when meta is missing', () => {
      createWrapper(
        {},
        {
          params: { id: '123' },
          matched: [
            {
              name: 'project-detail',
              path: '/projects/:id',
              parent: true,
              meta: { useId: true },
            },
          ],
        },
      );

      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
        { text: '123', to: { name: 'project-detail' } },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });
  });

  describe('when route has mixed matched routes', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          params: { id: '456' },
          matched: [
            {
              name: 'projects',
              path: '/projects',
              meta: { text: 'All Projects' },
            },
            {
              name: 'project-detail',
              path: '/projects/:id',
            },
            {
              name: 'project-issues',
              path: '/projects/:id/issues',
              meta: { text: 'Issues' },
              parent: true,
            },
          ],
        },
      );
    });

    it('combines static and route breadcrumbs correctly', () => {
      createWrapper(
        {},
        {
          params: { id: '456' },
          matched: [
            {
              path: '/projects',
              meta: {
                text: 'All Projects',
              },
            },
            {
              path: '/projects/:id',
              meta: { useId: true },
            },
            {
              path: '/projects/:id/project-issues',
              name: 'project-issues',
              parent: true,
              meta: { text: 'Issues' },
            },
          ],
        },
      );

      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
        { text: 'All Projects', to: { path: '/projects' } },
        { text: '456', to: { path: '/projects/:id' } },
        { text: 'Issues', to: { name: 'project-issues' } },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });
  });

  describe('when route has empty matched array', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          matched: [],
        },
      );
    });

    it('only shows static breadcrumbs', () => {
      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });
  });

  describe('when route has matched routes with empty meta', () => {
    beforeEach(() => {
      createWrapper(
        {},
        {
          params: {},
          matched: [
            {
              name: 'projects',
              path: '/projects',
              meta: {},
            },
          ],
        },
      );
    });

    it('filters out routes with empty meta and no id param', () => {
      const expectedCrumbs = [
        { text: 'Home', href: '/' },
        { text: 'Projects', href: '/projects' },
      ];

      expect(findGlBreadcrumb().props('items')).toMatchObject(expectedCrumbs);
    });
  });
});
