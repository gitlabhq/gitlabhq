import {
  planningViewAllItemsFilters,
  planningViewSavedViewFilterTokens,
  setPlanningViewAllItemsFilters,
  setPlanningViewSavedViewFilterTokens,
} from '~/work_items/pages/planning_view_state';

describe('planning_view_state', () => {
  beforeEach(() => {
    setPlanningViewAllItemsFilters(null);
    setPlanningViewSavedViewFilterTokens({});
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

  describe('setPlanningViewSavedViewFilterTokens', () => {
    it('updates planningViewSavedViewFilterTokens with the given value', () => {
      const tokens = { 42: [{ type: 'label', value: { data: 'bug' } }] };

      setPlanningViewSavedViewFilterTokens(tokens);

      expect(planningViewSavedViewFilterTokens.value).toEqual(tokens);
    });
  });
});
