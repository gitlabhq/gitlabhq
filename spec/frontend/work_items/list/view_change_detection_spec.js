import {
  ALL_ITEMS_DEFAULT_FILTER_TOKENS,
  filtersChanged,
  sortChanged,
  viewModeChanged,
  preferencesChanged,
} from '~/work_items/list/view_change_detection';

describe('view change detection', () => {
  const stateToken = { type: 'state', value: { data: 'opened', operator: '=' } };
  const labelToken = { type: 'label', value: { data: 'bug', operator: '=' } };

  describe('ALL_ITEMS_DEFAULT_FILTER_TOKENS', () => {
    it('is a single open-state token', () => {
      expect(ALL_ITEMS_DEFAULT_FILTER_TOKENS).toEqual([
        { type: 'state', value: { data: 'opened', operator: '=' } },
      ]);
    });
  });

  describe('filtersChanged', () => {
    it('returns false when tokens match the baseline regardless of order', () => {
      expect(
        filtersChanged({
          filterTokens: [stateToken, labelToken],
          baselineTokens: [labelToken, stateToken],
        }),
      ).toBe(false);
    });

    it('returns true when a token is added', () => {
      expect(
        filtersChanged({ filterTokens: [stateToken, labelToken], baselineTokens: [stateToken] }),
      ).toBe(true);
    });

    it('ignores the token id when comparing', () => {
      expect(
        filtersChanged({
          filterTokens: [{ ...stateToken, id: 'abc' }],
          baselineTokens: [stateToken],
        }),
      ).toBe(false);
    });

    it('drops empty filtered-search terms before comparing', () => {
      const emptySearch = { type: 'filtered-search-term', value: { data: '' } };

      expect(
        filtersChanged({ filterTokens: [stateToken, emptySearch], baselineTokens: [stateToken] }),
      ).toBe(false);
    });

    it('ignores the current search-term operator (normalized to undefined before comparing)', () => {
      expect(
        filtersChanged({
          filterTokens: [{ type: 'filtered-search-term', value: { data: 'foo', operator: '=' } }],
          baselineTokens: [
            { type: 'filtered-search-term', value: { data: 'foo', operator: undefined } },
          ],
        }),
      ).toBe(false);
    });
  });

  describe('sortChanged', () => {
    it.each`
      sortKey           | baselineSortKey   | expected
      ${'CREATED_DESC'} | ${'CREATED_DESC'} | ${false}
      ${'CREATED_DESC'} | ${'UPDATED_DESC'} | ${true}
    `(
      'returns $expected when sortKey=$sortKey and baseline=$baselineSortKey',
      ({ sortKey, baselineSortKey, expected }) => {
        expect(sortChanged({ sortKey, baselineSortKey })).toBe(expected);
      },
    );
  });

  describe('viewModeChanged', () => {
    it.each`
      viewMode   | baselineViewMode | expected
      ${'LIST'}  | ${'LIST'}        | ${false}
      ${'BOARD'} | ${'LIST'}        | ${true}
    `(
      'returns $expected when viewMode=$viewMode and baseline=$baselineViewMode',
      ({ viewMode, baselineViewMode, expected }) => {
        expect(viewModeChanged({ viewMode, baselineViewMode })).toBe(expected);
      },
    );
  });

  describe('preferencesChanged', () => {
    it('returns false when preferences match', () => {
      expect(
        preferencesChanged({
          currentPreferences: { hiddenMetadataKeys: ['labels'] },
          baselinePreferences: { hiddenMetadataKeys: ['labels'] },
        }),
      ).toBe(false);
    });

    it('returns true when preferences differ', () => {
      expect(
        preferencesChanged({
          currentPreferences: { hiddenMetadataKeys: ['labels'] },
          baselinePreferences: { hiddenMetadataKeys: [] },
        }),
      ).toBe(true);
    });

    it('returns true when collapsedGroups differ', () => {
      expect(
        preferencesChanged({
          currentPreferences: { collapsedGroups: ['status:gid://gitlab/Status/1'] },
          baselinePreferences: { collapsedGroups: [] },
        }),
      ).toBe(true);
    });

    it('returns false when collapsedGroups match', () => {
      expect(
        preferencesChanged({
          currentPreferences: { collapsedGroups: ['status:gid://gitlab/Status/1'] },
          baselinePreferences: { collapsedGroups: ['status:gid://gitlab/Status/1'] },
        }),
      ).toBe(false);
    });

    it('returns true when visibleGroups differ', () => {
      expect(
        preferencesChanged({
          currentPreferences: { visibleGroups: ['status:gid://gitlab/Status/1'] },
          baselinePreferences: { visibleGroups: null },
        }),
      ).toBe(true);
    });

    it('returns false when visibleGroups match', () => {
      expect(
        preferencesChanged({
          currentPreferences: { visibleGroups: ['status:gid://gitlab/Status/1'] },
          baselinePreferences: { visibleGroups: ['status:gid://gitlab/Status/1'] },
        }),
      ).toBe(false);
    });

    it('treats missing tracked keys as empty arrays and visibleGroups as null', () => {
      expect(
        preferencesChanged({
          currentPreferences: { hiddenMetadataKeys: [], visibleGroups: null },
          baselinePreferences: {},
        }),
      ).toBe(false);
    });
  });
});
