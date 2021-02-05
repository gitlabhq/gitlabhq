import { setHTMLFixture } from 'helpers/fixtures';
import RecentSearchesRoot from '~/filtered_search/recent_searches_root';

const containerId = 'test-container';
const dropdownElementId = 'test-dropdown-element';

describe('RecentSearchesRoot', () => {
  describe('render', () => {
    let recentSearchesRootMockInstance;
    let vm;
    let containerEl;

    beforeEach(() => {
      setHTMLFixture(`
        <div id="${containerId}">
          <div id="${dropdownElementId}"></div>
        </div>
      `);

      containerEl = document.getElementById(containerId);

      recentSearchesRootMockInstance = {
        store: {
          state: {
            recentSearches: ['foo', 'bar', 'qux'],
            isLocalStorageAvailable: true,
            allowedKeys: ['test'],
          },
        },
        wrapperElement: document.getElementById(dropdownElementId),
      };

      RecentSearchesRoot.prototype.render.call(recentSearchesRootMockInstance);
      vm = recentSearchesRootMockInstance.vm;

      return vm.$nextTick();
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should render the recent searches', () => {
      const { recentSearches } = recentSearchesRootMockInstance.store.state;

      recentSearches.forEach((recentSearch) => {
        expect(containerEl.textContent).toContain(recentSearch);
      });
    });
  });
});
