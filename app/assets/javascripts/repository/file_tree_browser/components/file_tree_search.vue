<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { s__ } from '~/locale';
import HighlightedText from '~/vue_shared/components/highlighted_text.vue';
import { joinPaths, buildURLwithRefType } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';
import { ARROW_DOWN_KEY, ARROW_UP_KEY, ENTER_KEY, ESC_KEY } from '~/lib/utils/keys';
import { FOCUS_FILE_TREE_BROWSER_FILTER_BAR, keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import { InternalEvents } from '~/tracking';

export default {
  name: 'FileTreeSearch',
  components: {
    GlLoadingIcon,
    GlIcon,
    HighlightedText,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
    escapedRef: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchQuery: '',
      searchResults: [],
      loadError: false,
      showSearchPanel: false,
      focusedIndex: -1,
      allFiles: [],
      filesLoaded: false,
      isLoading: false,
    };
  },
  computed: {
    filterSearchShortcutKey() {
      if (this.shortcutsDisabled) {
        return null;
      }
      return keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR)[0];
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    hasResults() {
      return this.searchResults.length > 0;
    },
  },
  watch: {
    filesLoaded(loaded) {
      if (loaded && this.searchQuery) {
        this.searchFiles(this.searchQuery);
      }
    },
    searchResults() {
      this.focusedIndex = -1;
    },
  },
  mounted() {
    this.debouncedSearchFiles = debounce(this.searchFiles, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    this.mousetrap = new Mousetrap();

    if (!this.shortcutsDisabled) {
      this.mousetrap.bind(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR), this.focusSearchInput);
    }
  },
  beforeDestroy() {
    this.mousetrap.unbind(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR));
  },
  methods: {
    focusSearchInput() {
      this.trackEvent('focus_file_tree_browser_filter_bar_on_repository_page', {
        label: 'shortcut',
      });
      this.$refs.searchInput?.focus();
    },
    async loadAllFiles() {
      this.isLoading = true;

      try {
        const url = joinPaths('/', this.projectPath, '-', 'files', this.escapedRef);
        const { data } = await axios.get(url);

        this.allFiles = data.map((filePath) => {
          const routerPath = buildURLwithRefType({
            path: joinPaths(
              '/',
              '-/blob',
              this.escapedRef,
              filePath.split('/').map(encodeURIComponent).join('/'),
            ),
            refType: this.refType,
          });

          return {
            id: filePath,
            path: filePath,
            routerPath,
          };
        });

        this.filesLoaded = true;
        this.loadError = false;
      } catch (error) {
        this.filesLoaded = false;
        this.loadError = true;
      } finally {
        this.isLoading = false;
      }
    },
    onSearchInput(query) {
      this.searchQuery = query;
      this.showSearchPanel = Boolean(query);

      if (!query || !this.filesLoaded) {
        return;
      }

      this.debouncedSearchFiles(query);
    },
    async onSearchFocus() {
      this.trackEvent('focus_file_tree_browser_filter_bar_on_repository_page', {
        label: 'click',
      });

      if (!this.filesLoaded && !this.isLoading) {
        await this.loadAllFiles();
      }
    },
    searchFiles(query) {
      if (!query || query.length < 1) {
        this.searchResults = [];
        return;
      }

      const filteredItems = fuzzaldrinPlus.filter(this.allFiles, query, {
        key: 'path',
        maxResults: 20,
      });
      this.searchResults = filteredItems;
    },
    handleResultClick(result) {
      this.$router.push(result.routerPath);
      this.searchQuery = '';
      this.showSearchPanel = false;
    },
    handleKeydown(event) {
      const { key } = event;
      const items = this.getResultItems();

      if (key === ARROW_DOWN_KEY) {
        event.preventDefault();
        this.focusedIndex = Math.min(this.focusedIndex + 1, items.length - 1);
        this.focusItem();
      } else if (key === ARROW_UP_KEY) {
        event.preventDefault();
        this.focusedIndex = Math.max(this.focusedIndex - 1, -1);
        if (this.focusedIndex === -1) {
          this.$refs.searchInput?.focus();
        } else {
          this.focusItem();
        }
      } else if (key === ENTER_KEY) {
        event.preventDefault();
        if (this.focusedIndex >= 0 && items[this.focusedIndex]) {
          items[this.focusedIndex].querySelector('button')?.click();
        }
      } else if (key === ESC_KEY) {
        event.preventDefault();
        this.clearSearch();
      }
    },
    getResultItems() {
      return Array.from(
        this.$refs.resultsList?.querySelectorAll('.file-tree-search-result-item') || [],
      );
    },
    focusItem() {
      const items = this.getResultItems();
      if (items[this.focusedIndex]) {
        items[this.focusedIndex].focus();
      }
    },
    clearSearch() {
      this.searchQuery = '';
      this.showSearchPanel = false;
      this.$refs.searchInput?.focus();
    },
    handleInputKeydown(event) {
      if (!this.hasResults) return;
      event.preventDefault();
      this.focusedIndex = 0;
      this.focusItem();
    },
  },
  i18n: {
    searchLabel: s__('Repository|Search files (*.vue, *.rb...)'),
    noResults: s__('Repository|No results found'),
    errorMessage: s__('Repository|Something went wrong while loading the files'),
  },
};
</script>

<template>
  <div class="file-tree-search-wrapper gl-flex gl-w-full">
    <div class="gl-relative gl-flex gl-w-full gl-items-center gl-overflow-visible">
      <input
        ref="searchInput"
        v-model.trim="searchQuery"
        role="combobox"
        :aria-expanded="String(showSearchPanel)"
        aria-haspopup="listbox"
        aria-controls="file-tree-search-listbox"
        :aria-activedescendant="focusedIndex >= 0 ? `file-tree-search-result-${focusedIndex}` : ''"
        type="text"
        data-testid="file-tree-search-input"
        :placeholder="$options.i18n.searchLabel"
        :aria-label="$options.i18n.searchLabel"
        :aria-keyshortcuts="filterSearchShortcutKey"
        class="gl-border gl-w-full gl-rounded-lg gl-border-section gl-bg-section gl-px-3 gl-py-2 gl-text-secondary focus:gl-outline-none focus:gl-focus"
        @input="onSearchInput(searchQuery)"
        @focus="onSearchFocus"
        @keydown.escape="clearSearch"
        @keydown.down="handleInputKeydown"
      />
      <kbd
        v-if="!searchQuery.trim()"
        data-testid="file-tree-search-shortcut-key"
        class="gl-absolute gl-right-3 gl-hidden gl-shrink-0 gl-rounded-base gl-shadow-none md:gl-block"
      >
        {{ filterSearchShortcutKey }}
      </kbd>
      <button
        v-if="searchQuery"
        class="gl-absolute gl-right-3 gl-border-0 gl-bg-section gl-p-1 gl-pl-2 gl-text-subtle hover:gl-text-strong focus:gl-outline-none"
        :aria-label="__('Clear search')"
        @click="clearSearch"
      >
        <gl-icon name="clear" :size="16" />
      </button>
      <div
        v-if="showSearchPanel"
        class="file-tree-search-dropdown gl-absolute gl-left-0 gl-right-0 gl-top-full gl-z-200 gl-mt-1"
        @keydown="handleKeydown"
      >
        <div
          class="file-tree-search-dropdown-content gl-border gl-max-h-[24rem] gl-overflow-y-auto gl-rounded-lg gl-border-section gl-bg-section gl-shadow-lg"
        >
          <gl-loading-icon v-if="isLoading" size="sm" class="gl-flex gl-items-center gl-py-5" />

          <div
            v-else-if="loadError"
            class="gl-px-4 gl-py-3 gl-text-center gl-text-danger"
            data-testid="load-error-message"
          >
            {{ $options.i18n.errorMessage }}
          </div>

          <ul
            v-else-if="hasResults"
            id="file-tree-search-listbox"
            ref="resultsList"
            class="gl-m-0 gl-list-none gl-p-0"
            role="listbox"
          >
            <li
              v-for="(result, index) in searchResults"
              :id="`file-tree-search-result-${index}`"
              :key="result.id"
              :aria-selected="focusedIndex === index"
              :class="{ '!gl-bg-subtle': focusedIndex === index }"
              class="file-tree-search-result-item gl-m-1 gl-rounded-lg gl-px-2 gl-py-1 hover:gl-bg-subtle focus:gl-outline-none focus:gl-focus"
              role="option"
              tabindex="-1"
            >
              <button
                class="gl-w-full gl-border-0 gl-bg-transparent gl-text-left"
                @click="handleResultClick(result)"
              >
                <div class="gl-flex gl-items-start gl-gap-2 gl-py-2">
                  <gl-icon name="document" :size="16" class="gl-mt-1 gl-shrink-0 gl-text-subtle" />
                  <highlighted-text
                    :text="result.path"
                    :match="searchQuery"
                    class="gl-block gl-text-strong gl-wrap-anywhere"
                  />
                </div>
              </button>
            </li>
          </ul>

          <div
            v-else-if="!hasResults && !isLoading"
            class="gl-px-4 gl-py-5 gl-text-center gl-text-subtle"
          >
            {{ $options.i18n.noResults }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
