import {
  timeFormattedAsDate,
  timeFormattedAsDateFull,
  initializeFilterFromQueryParams,
  initializeSortFromQueryParams,
  convertFiltersToQueryParams,
  convertSortToQueryParams,
  groupPermissionsByResourceAndCategory,
} from '~/personal_access_tokens/utils';
import { mockGroupPermissions } from './mock_data';

describe('personal_access_tokens/utils', () => {
  describe('timeFormattedAsDate', () => {
    it.each([null, undefined, ''])('returns `Never` label when time is %p', (value) => {
      expect(timeFormattedAsDate(value)).toBe('Never');
    });

    it('formats date when time is provided', () => {
      expect(timeFormattedAsDate('2025-12-01T00:00:00Z')).toBe('Dec 1, 2025');
    });

    it('handles different date formats', () => {
      expect(timeFormattedAsDate('2025-12-01')).toBe('Dec 1, 2025');
    });
  });

  describe('timeFormattedAsDateFull', () => {
    it.each([null, undefined, ''])('returns `Never` label when time is %p', (value) => {
      expect(timeFormattedAsDateFull(value)).toBe('Never');
    });

    it('formats date when time is provided', () => {
      expect(timeFormattedAsDateFull('2025-12-01T00:00:00Z')).toBe(
        'December 1, 2025 at 12:00:00 AM GMT',
      );
    });

    it('handles different date formats', () => {
      expect(timeFormattedAsDateFull('2025-12-01')).toBe('December 1, 2025 at 12:00:00 AM GMT');
    });
  });

  describe('initializeFilterFromQueryParams', () => {
    beforeEach(() => {
      delete window.location;
    });

    it('returns default filter when no query params', () => {
      window.location = { search: '' };

      expect(initializeFilterFromQueryParams()).toEqual([
        {
          type: 'state',
          value: {
            data: 'ACTIVE',
            operator: '=',
          },
        },
      ]);
    });

    it('parses search parameter correctly', () => {
      window.location = { search: '?search=test-token' };

      expect(initializeFilterFromQueryParams()).toEqual([
        {
          type: 'filtered-search-term',
          value: {
            data: 'test-token',
          },
        },
      ]);
    });

    it('parses date parameteres correctly', () => {
      window.location = { search: '?created_after=2024-01-01&expires_before=2024-12-31' };

      expect(initializeFilterFromQueryParams()).toEqual([
        {
          type: 'created',
          value: {
            data: '2024-01-01',
            operator: '≥',
          },
        },
        {
          type: 'expires',
          value: {
            data: '2024-12-31',
            operator: '<',
          },
        },
      ]);
    });

    it('parses boolean values correctly', () => {
      window.location = { search: '?revoked=true' };

      expect(initializeFilterFromQueryParams()).toEqual([
        {
          type: 'revoked',
          value: {
            data: true,
            operator: '=',
          },
        },
      ]);
    });

    it('parses enum values correctly', () => {
      window.location = { search: '?state=active' };

      expect(initializeFilterFromQueryParams()).toEqual([
        {
          type: 'state',
          value: {
            data: 'ACTIVE',
            operator: '=',
          },
        },
      ]);
    });

    it('ignores unknown filter types', () => {
      window.location = { search: '?unknown_filter=value&state=active' };

      const result = initializeFilterFromQueryParams();

      expect(result).toEqual([
        {
          type: 'state',
          value: {
            data: 'ACTIVE',
            operator: '=',
          },
        },
      ]);
    });
  });

  describe('initializeSortFromQueryParams', () => {
    beforeEach(() => {
      delete window.location;
    });

    it('returns default sort when no sort param', () => {
      window.location = { search: '' };

      expect(initializeSortFromQueryParams()).toEqual({
        value: 'expires',
        isAsc: true,
      });
    });

    it('parses ascending sort correctly', () => {
      window.location = { search: '?sort=created_asc' };

      expect(initializeSortFromQueryParams()).toEqual({
        value: 'created',
        isAsc: true,
      });
    });

    it('parses descending sort correctly', () => {
      window.location = { search: '?sort=expires_desc' };

      expect(initializeSortFromQueryParams()).toEqual({
        value: 'expires',
        isAsc: false,
      });
    });

    it('ignores invalid sort value', () => {
      window.location = { search: '?sort=invalid_sort' };

      expect(initializeSortFromQueryParams()).toEqual({
        value: 'expires',
        isAsc: true,
      });
    });
  });

  describe('convertFiltersToQueryParams', () => {
    it('converts filter object to snake_case keys and lowercase values', () => {
      const filterObject = {
        search: 'test-token',
        createdAfter: '2024-01-01',
        expiresBefore: '2024-12-31',
        state: 'ACTIVE',
        revoked: true,
      };

      expect(convertFiltersToQueryParams(filterObject)).toEqual({
        search: 'test-token',
        created_after: '2024-01-01',
        expires_before: '2024-12-31',
        state: 'active',
        revoked: 'true',
      });
    });

    it('handles empty filter object', () => {
      const result = convertFiltersToQueryParams({});

      expect(result).toEqual({});
    });
  });

  describe('convertSortToQueryParams', () => {
    it('formats ascending sort parameter correctly', () => {
      const sort = { value: 'created', isAsc: true };

      expect(convertSortToQueryParams(sort)).toEqual({
        sort: 'created_asc',
      });
    });

    it('formats descending sort parameter correctly', () => {
      const sort = { value: 'expires', isAsc: false };

      expect(convertSortToQueryParams(sort)).toEqual({
        sort: 'expires_desc',
      });
    });
  });

  describe('groupPermissionsByResourceAndCategory', () => {
    it('groups permissions by resources and category', () => {
      expect(groupPermissionsByResourceAndCategory(mockGroupPermissions)).toEqual([
        {
          key: 'groups_and_projects',
          name: 'Groups and projects',
          resources: [
            {
              description: 'Project resource description',
              key: 'project',
              name: 'Project',
            },
          ],
        },
        {
          key: 'merge_request',
          name: 'Merge request',
          resources: [
            {
              description: 'Repository resource description',
              key: 'repository',
              name: 'Repository',
            },
          ],
        },
      ]);
    });
  });
});
