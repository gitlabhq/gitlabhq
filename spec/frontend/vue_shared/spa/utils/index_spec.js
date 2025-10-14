import { extractNavScopeFromRoute, activeNavigationWatcher } from '~/vue_shared/spa/utils';
import { updateActiveNavigation } from '~/vue_shared/spa/utils/dom_utils';

jest.mock('~/vue_shared/spa/utils/dom_utils');

describe('SPA utils index', () => {
  describe('extractNavScopeFromRoute', () => {
    it('returns empty string when route is undefined', () => {
      expect(extractNavScopeFromRoute()).toBe('');
    });

    it('returns empty string when route has no matched property', () => {
      const route = {};
      expect(extractNavScopeFromRoute(route)).toBe('');
    });

    it('returns empty string when matched array is empty', () => {
      const route = { matched: [] };
      expect(extractNavScopeFromRoute(route)).toBe('');
    });

    it('returns the first segment when path has only one segment', () => {
      const route = { matched: [{ path: '/dashboard' }] };
      expect(extractNavScopeFromRoute(route)).toBe('dashboard');
    });

    it('returns the second segment when path has multiple segments', () => {
      const route = { matched: [{ path: '/groups/my-group' }] };
      expect(extractNavScopeFromRoute(route)).toBe('groups');
    });
  });

  describe('activeNavigationWatcher', () => {
    const mockNext = jest.fn();

    it('calls next function', () => {
      const to = { matched: [{ path: '/projects/test' }] };
      const from = { matched: [{ path: '/groups/test' }] };

      activeNavigationWatcher(to, from, mockNext);

      expect(mockNext).toHaveBeenCalledTimes(1);
    });

    it('calls updateActiveNavigation when scope changes', () => {
      const to = { matched: [{ path: '/projects/test' }] };
      const from = { matched: [{ path: '/groups/test' }] };

      activeNavigationWatcher(to, from, mockNext);

      expect(updateActiveNavigation).toHaveBeenCalledWith('projects');
    });

    it('does not call updateActiveNavigation when scope remains the same', () => {
      const to = { matched: [{ path: '/projects/test1' }] };
      const from = { matched: [{ path: '/projects/test2' }] };

      activeNavigationWatcher(to, from, mockNext);

      expect(updateActiveNavigation).not.toHaveBeenCalled();
    });

    it('calls updateActiveNavigation when from route has no matched routes', () => {
      const to = { matched: [{ path: '/projects/test' }] };
      const from = { matched: [] };

      activeNavigationWatcher(to, from, mockNext);

      expect(updateActiveNavigation).toHaveBeenCalledWith('projects');
    });
  });
});
