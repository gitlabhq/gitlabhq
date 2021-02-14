import * as types from '~/whats_new/store/mutation_types';
import mutations from '~/whats_new/store/mutations';
import createState from '~/whats_new/store/state';

describe('whats new mutations', () => {
  let state;

  beforeEach(() => {
    state = createState;
  });

  describe('openDrawer', () => {
    it('sets open to true', () => {
      mutations[types.OPEN_DRAWER](state);
      expect(state.open).toBe(true);
    });
  });

  describe('closeDrawer', () => {
    it('sets open to false', () => {
      mutations[types.CLOSE_DRAWER](state);
      expect(state.open).toBe(false);
    });
  });

  describe('addFeatures', () => {
    it('adds features from data', () => {
      mutations[types.ADD_FEATURES](state, ['bells and whistles']);
      expect(state.features).toEqual(['bells and whistles']);
    });

    it('when there are already items, it adds items', () => {
      state.features = ['shiny things'];
      mutations[types.ADD_FEATURES](state, ['bells and whistles']);
      expect(state.features).toEqual(['shiny things', 'bells and whistles']);
    });
  });

  describe('setPageInfo', () => {
    it('sets page info', () => {
      mutations[types.SET_PAGE_INFO](state, { nextPage: 8 });
      expect(state.pageInfo).toEqual({ nextPage: 8 });
    });
  });

  describe('setFetching', () => {
    it('sets fetching', () => {
      mutations[types.SET_FETCHING](state, true);
      expect(state.fetching).toBe(true);
    });
  });

  describe('setDrawerBodyHeight', () => {
    it('sets drawerBodyHeight', () => {
      mutations[types.SET_DRAWER_BODY_HEIGHT](state, 840);
      expect(state.drawerBodyHeight).toBe(840);
    });
  });
});
