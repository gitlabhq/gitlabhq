import Vue from 'vue';
import RecentSearchesDropdownContent from './components/recent_searches_dropdown_content.vue';
import eventHub from './event_hub';

class RecentSearchesRoot {
  constructor(
    recentSearchesStore,
    recentSearchesService,
    wrapperElement,
  ) {
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
    const state = this.store.state;
    this.vm = new Vue({
      el: this.wrapperElement,
      components: {
        RecentSearchesDropdownContent,
      },
      data() { return state; },
      template: `
        <recent-searches-dropdown-content
          :items="recentSearches"
          :is-local-storage-available="isLocalStorageAvailable"
          :allowed-keys="allowedKeys"
          />
      `,
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
