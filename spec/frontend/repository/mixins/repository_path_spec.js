import { shallowMount } from '@vue/test-utils';
import repositoryPathMixin from '~/repository/mixins/repository_path';

describe('repositoryPath mixin', () => {
  let wrapper;

  const createComponent = ({ routeData = {} } = {}) => {
    const TestComponent = {
      mixins: [repositoryPathMixin],
      template: '<div>{{ computedPath }}</div>',
    };

    wrapper = shallowMount(TestComponent, {
      mocks: {
        $route: routeData,
      },
    });
  };

  describe('when route is active', () => {
    it('returns normalized route path for a file', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: 'README.md' },
          path: '/-/tree/master/README.md',
        },
      });

      expect(wrapper.vm.computedPath).toBe('README.md');
    });

    it('returns normalized route path for nested folder', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: 'src/app/components' },
          path: '/-/tree/master/src/app/components',
        },
      });

      expect(wrapper.vm.computedPath).toBe('src/app/components');
    });

    it('returns "/" when route path param is undefined', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: undefined },
          path: '/-/tree/master/',
        },
      });

      expect(wrapper.vm.computedPath).toBe('/');
    });

    it('returns "/" when route path param is empty string', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: '' },
          path: '/-/tree/master/',
        },
      });

      expect(wrapper.vm.computedPath).toBe('/');
    });

    it('handles array path params from Vue Router 4', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: ['src', 'app', 'components'] },
          path: '/-/tree/master/src/app/components',
        },
      });

      expect(wrapper.vm.computedPath).toBe('src/app/components');
    });

    it('handles single-element array path params', () => {
      createComponent({
        routeData: {
          name: 'blobPath',
          params: { path: ['README.md'] },
          path: '/-/blob/master/README.md',
        },
      });

      expect(wrapper.vm.computedPath).toBe('README.md');
    });

    it('handles empty array path params', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: [] },
          path: '/-/tree/master/',
        },
      });

      // Empty array joins to empty string, falls back to '/'
      expect(wrapper.vm.computedPath).toBe('/');
    });
  });

  describe('when route is not available', () => {
    it('returns "/" when route is undefined', () => {
      createComponent({
        routeData: undefined,
      });

      expect(wrapper.vm.computedPath).toBe('/');
    });

    it('returns "/" when route params are undefined', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: {},
        },
      });

      expect(wrapper.vm.computedPath).toBe('/');
    });
  });

  describe('edge cases', () => {
    it('handles route with empty params object', () => {
      createComponent({
        routeData: {
          name: 'projectRoot',
          params: {},
          path: '/',
        },
      });

      expect(wrapper.vm.computedPath).toBe('/');
    });

    it('handles null route path param', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: null },
          path: '/-/tree/master/',
        },
      });

      // null is falsy, should fall back to '/'
      expect(wrapper.vm.computedPath).toBe('/');
    });

    it('handles route path with special characters', () => {
      createComponent({
        routeData: {
          name: 'treePath',
          params: { path: 'path/with spaces/and-special!@#.md' },
          path: '/-/tree/master/path/with spaces/and-special!@#.md',
        },
      });

      expect(wrapper.vm.computedPath).toBe('path/with spaces/and-special!@#.md');
    });

    it('handles very deeply nested paths', () => {
      const deepPath = 'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/file.txt';
      createComponent({
        routeData: {
          name: 'blobPath',
          params: { path: deepPath },
          path: `/-/blob/master/${deepPath}`,
        },
      });

      expect(wrapper.vm.computedPath).toBe(deepPath);
    });
  });
});
