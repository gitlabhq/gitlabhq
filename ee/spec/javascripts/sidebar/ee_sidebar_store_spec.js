import SidebarStore from 'ee/sidebar/stores/sidebar_store';
import CESidebarStore from '~/sidebar/stores/sidebar_store';

describe('EE Sidebar store', () => {
  let store;
  beforeEach(() => {
    store = new SidebarStore({
      weight: null,
      weightOptions: ['None', 0, 1, 3],
      weightNoneValue: 'None',
    });
  });

  afterEach(() => {
    // Since CESidebarStore stores the actual singleton instance
    // we need to clear that specific reference
    CESidebarStore.singleton = null;
  });

  it('sets weight data', () => {
    expect(store.weight).toEqual(null);

    const weight = 3;
    store.setWeightData({
      weight,
    });

    expect(store.isFetching.weight).toEqual(false);
    expect(store.weight).toEqual(weight);
  });

  it('set weight', () => {
    expect(store.weight).toEqual(null);
    const weight = 1;
    store.setWeight(weight);

    expect(store.weight).toEqual(weight);
  });
});
