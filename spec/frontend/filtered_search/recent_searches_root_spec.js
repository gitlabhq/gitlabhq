import { nextTick } from 'vue';
import { setHTMLFixture } from 'helpers/fixtures';
import RecentSearchesRoot from '~/filtered_search/recent_searches_root';
import eventHub from '~/filtered_search/event_hub';

const containerId = 'test-container';
const dropdownElementId = 'test-dropdown-element';

describe('RecentSearchesRoot', () => {
  describe('render', () => {
    let recentSearchesRoot;
    let store;
    let service;
    let containerEl;

    beforeEach(async () => {
      setHTMLFixture(`
        <div id="${containerId}">
          <div id="${dropdownElementId}"></div>
        </div>
      `);

      containerEl = document.getElementById(containerId);

      store = {
        state: {
          recentSearches: ['foo', 'bar', 'qux'],
          isLocalStorageAvailable: true,
          allowedKeys: ['test'],
        },
        setRecentSearches: jest.fn((searches) => searches),
      };
      service = {
        save: jest.fn(),
      };

      recentSearchesRoot = new RecentSearchesRoot(
        store,
        service,
        document.getElementById(dropdownElementId),
      );
      recentSearchesRoot.init();

      await nextTick();
    });

    afterEach(() => {
      recentSearchesRoot.destroy();
    });

    it('should render the recent searches', () => {
      store.state.recentSearches.forEach((recentSearch) => {
        expect(containerEl.textContent).toContain(recentSearch);
      });
    });

    it('renders searches received via the recent-searches-updated event after mount', async () => {
      eventHub.$emit('recent-searches-updated', ['added-after-mount']);

      await nextTick();

      expect(containerEl.textContent).toContain('added-after-mount');
    });

    it('clears the rendered searches on request-clear-recent-searches', async () => {
      eventHub.$emit('request-clear-recent-searches');

      await nextTick();

      expect(store.setRecentSearches).toHaveBeenCalledWith([]);
      expect(service.save).toHaveBeenCalledWith([]);
      expect(containerEl.textContent).toContain("You don't have any recent searches");
    });

    it('unsubscribes from the event hub on destroy', () => {
      const offSpy = jest.spyOn(eventHub, '$off');
      const { vm } = recentSearchesRoot;

      recentSearchesRoot.destroy();

      expect(offSpy).toHaveBeenCalledWith('recent-searches-updated', vm.onRecentSearchesUpdated);
      expect(offSpy).toHaveBeenCalledWith(
        'request-clear-recent-searches',
        vm.onRequestClearRecentSearches,
      );
    });
  });
});
