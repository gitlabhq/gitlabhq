import Vue from 'vue';
import RecentSearchesRoot from '~/filtered_search/recent_searches_root';

jest.mock('vue');

describe('RecentSearchesRoot', () => {
  describe('render', () => {
    let recentSearchesRoot;
    let data;
    let template;

    beforeEach(() => {
      recentSearchesRoot = {
        store: {
          state: 'state',
        },
      };

      Vue.mockImplementation(options => {
        ({ data, template } = options);
      });

      RecentSearchesRoot.prototype.render.call(recentSearchesRoot);
    });

    it('should instantiate Vue', () => {
      expect(Vue).toHaveBeenCalled();
      expect(data()).toBe(recentSearchesRoot.store.state);
      expect(template).toContain(':is-local-storage-available="isLocalStorageAvailable"');
    });
  });
});
