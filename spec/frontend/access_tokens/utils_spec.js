import { DEFAULT_FILTER, DEFAULT_SORT } from '~/access_tokens/constants';
import {
  initializeFilters,
  initializeSort,
  initializeValuesFromQuery,
} from '~/access_tokens/utils';

describe('initializeFilters', () => {
  it('returns correct value of search', () => {
    expect(initializeFilters({}, 'dummy')).toEqual(['dummy']);
  });

  it('returns correct value of filter', () => {
    expect(initializeFilters({ revoked: 'false' })).toEqual([
      { type: 'revoked', value: { data: 'false', operator: '=' } },
    ]);
  });

  it('returns correct value for filters ending with `before`', () => {
    expect(initializeFilters({ created_before: '2025-01-01' })).toEqual([
      { type: 'created', value: { data: '2025-01-01', operator: '<' } },
    ]);
  });

  it('returns correct value for filters ending with `after`', () => {
    expect(initializeFilters({ last_used_after: '2024-01-01' })).toEqual([
      { type: 'last_used', value: { data: '2024-01-01', operator: '≥' } },
    ]);
  });

  it('when `isCredentialsInventory` is false and no filters or search term are provided, it returns a default filter', () => {
    expect(initializeFilters({})).toEqual(DEFAULT_FILTER);
  });

  it('when `isCredentialsInventory` is true and no filters or search term are provided, it returns an empty array', () => {
    expect(initializeFilters({}, '', true)).toEqual([]);
  });
});

describe('initializeSort', () => {
  it('returns default sort when no sort is provided', () => {
    expect(initializeSort()).toEqual(DEFAULT_SORT);
  });

  it('returns correct value of sort', () => {
    expect(initializeSort('name_desc')).toEqual({ value: 'name', isAsc: false });
  });
});

describe('initializeValuesFromQuery', () => {
  it('returns correct object when `isCredentialsInventory` is false', () => {
    expect(initializeValuesFromQuery(false, '?page=1&revoked=true&sort=expires_asc')).toMatchObject(
      {
        filters: [{ type: 'revoked', value: { data: 'true', operator: '=' } }],
        page: 1,
        sorting: { value: 'expires', isAsc: true },
      },
    );
  });

  it('returns correct object when `isCredentialsInventory` is true', () => {
    expect(initializeValuesFromQuery(true, '?page=1&revoked=true&sort=expires_asc')).toMatchObject({
      tokens: [{ type: 'revoked', value: { data: 'true', operator: '=' } }],
      page: 1,
      sorting: { value: 'expires', isAsc: true },
    });
  });
});
