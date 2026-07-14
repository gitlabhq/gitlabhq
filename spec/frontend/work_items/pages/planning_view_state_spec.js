import {
  planningViewAllItemsFilters,
  setPlanningViewAllItemsFilters,
  getSavedViewSessionFilters,
  setSavedViewSessionFilters,
  resetPlanningViewState,
} from '~/work_items/pages/planning_view_state';

describe('planning_view_state', () => {
  beforeEach(() => {
    resetPlanningViewState();
  });

  describe('setPlanningViewAllItemsFilters', () => {
    it('updates planningViewAllItemsFilters with the given value', () => {
      const filters = {
        filterTokens: [{ type: 'author', value: { data: 'root' } }],
        sortKey: 'CREATED_DESC',
        state: 'opened',
      };

      setPlanningViewAllItemsFilters(filters);

      expect(planningViewAllItemsFilters.value).toEqual(filters);
    });
  });

  describe('setSavedViewSessionFilters', () => {
    it('stores a copy of the tokens under the view id, preserving other views', () => {
      const existing = [{ type: 'author', value: { data: 'root' } }];
      setSavedViewSessionFilters('7', existing);

      const tokens = [{ type: 'label', value: { data: 'bug' } }];
      setSavedViewSessionFilters('42', tokens);

      expect(getSavedViewSessionFilters('7')).toEqual(existing);
      expect(getSavedViewSessionFilters('42')).toEqual(tokens);
      expect(getSavedViewSessionFilters('42')).not.toBe(tokens);
    });
  });

  describe('getSavedViewSessionFilters', () => {
    it('returns the stored tokens for a view id', () => {
      const tokens = [{ type: 'label', value: { data: 'bug' } }];
      setSavedViewSessionFilters('42', tokens);

      expect(getSavedViewSessionFilters('42')).toEqual(tokens);
    });

    it('returns undefined when no tokens are stored for the view id', () => {
      expect(getSavedViewSessionFilters('99')).toBeUndefined();
    });
  });
});
