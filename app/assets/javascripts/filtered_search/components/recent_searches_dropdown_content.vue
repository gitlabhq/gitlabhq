<script>
import eventHub from '../event_hub';
import FilteredSearchTokenizer from '../filtered_search_tokenizer';

export default {
  name: 'RecentSearchesDropdownContent',
  props: {
    items: {
      type: Array,
      required: true,
    },
    isLocalStorageAvailable: {
      type: Boolean,
      required: false,
      default: true,
    },
    allowedKeys: {
      type: Array,
      required: true,
    },
  },
  computed: {
    /**
     * Both Epic and Roadmap pages share same recents store
     * and with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36421
     * Roadmap started using `GlFilteredSearch` which is not compatible
     * with string tokens stored in recents, so this is a temporary
     * fix by ignoring non-string recents while in Epic page.
     */
    compatibleItems() {
      return this.items.filter((item) => typeof item === 'string');
    },
    processedItems() {
      return this.compatibleItems.map((item) => {
        const { tokens, searchToken } = FilteredSearchTokenizer.processTokens(
          item,
          this.allowedKeys,
        );

        const resultantTokens = tokens.map((token) => ({
          prefix: `${token.key}:`,
          operator: token.operator,
          suffix: `${token.symbol}${token.value}`,
        }));

        return {
          text: item,
          tokens: resultantTokens,
          searchToken,
        };
      });
    },
    hasItems() {
      return this.compatibleItems.length > 0;
    },
  },
  methods: {
    onItemActivated(text) {
      eventHub.$emit('recentSearchesItemSelected', text);
    },
    onRequestClearRecentSearches(e) {
      // Stop the dropdown from closing
      e.stopPropagation();

      eventHub.$emit('requestClearRecentSearches');
    },
  },
};
</script>
<template>
  <div>
    <div
      v-if="!isLocalStorageAvailable"
      data-testid="local-storage-note"
      class="dropdown-info-note"
    >
      {{ __('This feature requires local storage to be enabled') }}
    </div>
    <ul v-else-if="hasItems">
      <li
        v-for="(item, index) in processedItems"
        :key="`processed-items-${index}`"
        data-testid="dropdown-item"
      >
        <button
          type="button"
          class="filtered-search-history-dropdown-item js-dropdown-button"
          @click="onItemActivated(item.text)"
        >
          <span>
            <span
              v-for="(token, tokenIndex) in item.tokens"
              :key="`dropdown-token-${tokenIndex}`"
              class="filtered-search-history-dropdown-token js-dropdown-token"
            >
              <span class="name">{{ token.prefix }}</span>
              <span class="name">{{ token.operator }}</span>
              <span class="value">{{ token.suffix }}</span>
            </span>
          </span>
          <span class="filtered-search-history-dropdown-search-token">{{ item.searchToken }}</span>
        </button>
      </li>
      <li class="divider"></li>
      <li>
        <button
          data-testid="clear-button"
          type="button"
          class="filtered-search-history-clear-button"
          @click="onRequestClearRecentSearches($event)"
        >
          {{ __('Clear recent searches') }}
        </button>
      </li>
    </ul>
    <div v-else data-testid="dropdown-note" class="dropdown-info-note">
      {{ __("You don't have any recent searches") }}
    </div>
  </div>
</template>
