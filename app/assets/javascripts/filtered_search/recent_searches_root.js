import Vue from 'vue';
import RecentSearchesDropdownContent from './components/recent_searches_dropdown_content.vue';
import eventHub from './event_hub';

class RecentSearchesRoot {
  constructor(recentSearchesStore, recentSearchesService, wrapperElement) {
    this.store = recentSearchesStore;
    this.service = recentSearchesService;
    this.wrapperElement = wrapperElement;
  }

  init() {
    this.bindEvents();
    this.render();
  }

  bindEvents() {
    this.onRequestClearRecentSearchesWrapper = this.onRequestClearRecentSearches.bind(this);

    eventHub.$on('requestClearRecentSearches', this.onRequestClearRecentSearchesWrapper);
  }

  unbindEvents() {
    eventHub.$off('requestClearRecentSearches', this.onRequestClearRecentSearchesWrapper);
  }

  render() {
    const { state } = this.store;
    this.vm = new Vue({
      el: this.wrapperElement,
      data() {
        return state;
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

  onRequestClearRecentSearches() {
    const resultantSearches = this.store.setRecentSearches([]);
    this.service.save(resultantSearches);
  }

  destroy() {
    this.unbindEvents();
    if (this.vm) {
      this.vm.$destroy();
    }
  }
}

export default RecentSearchesRoot;
