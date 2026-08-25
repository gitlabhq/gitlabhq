import Vue from 'vue';
import RecentSearchesDropdownContent from './components/recent_searches_dropdown_content.vue';
import eventHub from './event_hub';

// Legacy filtered-search engine, superseded by
// ~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue. New pages should use
// that Vue component instead of this class.
class RecentSearchesRoot {
  constructor(recentSearchesStore, recentSearchesService, wrapperElement) {
    this.store = recentSearchesStore;
    this.service = recentSearchesService;
    this.wrapperElement = wrapperElement;
  }

  init() {
    this.render();
  }

  render() {
    const { store, service } = this;
    const { state } = store;

    this.vm = new Vue({
      el: this.wrapperElement,
      name: 'RecentSearchesDropdownContentRoot',
      data() {
        return { ...state };
      },
      created() {
        eventHub.$on('recent-searches-updated', this.onRecentSearchesUpdated);
        eventHub.$on('request-clear-recent-searches', this.onRequestClearRecentSearches);
      },
      beforeDestroy() {
        eventHub.$off('recent-searches-updated', this.onRecentSearchesUpdated);
        eventHub.$off('request-clear-recent-searches', this.onRequestClearRecentSearches);
      },
      methods: {
        onRecentSearchesUpdated(searches) {
          this.recentSearches = searches;
        },
        onRequestClearRecentSearches() {
          const resultantSearches = store.setRecentSearches([]);
          service.save(resultantSearches);
          this.recentSearches = resultantSearches;
        },
      },
      render(h) {
        return h(RecentSearchesDropdownContent, {
          props: {
            items: this.recentSearches,
            isLocalStorageAvailable: this.isLocalStorageAvailable,
            allowedKeys: this.allowedKeys,
          },
        });
      },
    });
  }

  destroy() {
    if (this.vm) {
      this.vm.$destroy();
    }
  }
}

export default RecentSearchesRoot;
