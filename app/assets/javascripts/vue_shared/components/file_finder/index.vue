<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import VirtualList from 'vue-virtual-scroll-list';
import { Mousetrap, addStopCallback } from '~/lib/mousetrap';
import { keysFor, MR_GO_TO_FILE } from '~/behaviors/shortcuts/keybindings';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import Item from './item.vue';

export const MAX_FILE_FINDER_RESULTS = 40;
export const FILE_FINDER_ROW_HEIGHT = 55;

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    Item,
    VirtualList,
  },
  props: {
    files: {
      type: Array,
      required: true,
    },
    visible: {
      type: Boolean,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    showDiffStats: {
      type: Boolean,
      required: false,
      default: false,
    },
    clearSearchOnClose: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      focusedIndex: -1,
      searchText: '',
      mouseOver: false,
      cancelMouseOver: false,
    };
  },
  computed: {
    filteredBlobs() {
      const searchText = this.searchText.trim();

      if (searchText === '') {
        return this.files.slice(0, MAX_FILE_FINDER_RESULTS);
      }

      return fuzzaldrinPlus.filter(this.files, searchText, {
        key: 'path',
        maxResults: MAX_FILE_FINDER_RESULTS,
      });
    },
    filteredBlobsLength() {
      return this.filteredBlobs.length;
    },
    listShowCount() {
      return this.filteredBlobsLength ? Math.min(this.filteredBlobsLength, 5) : 1;
    },
    listHeight() {
      return FILE_FINDER_ROW_HEIGHT;
    },
    showClearInputButton() {
      return this.searchText.trim() !== '';
    },
  },
  watch: {
    visible() {
      this.$nextTick(() => {
        if (!this.visible) {
          if (this.clearSearchOnClose) {
            this.searchText = '';
          }
        } else {
          this.focusedIndex = 0;

          if (this.$refs.searchInput) {
            this.$refs.searchInput.focus();
          }
        }
      });
    },
    searchText() {
      this.focusedIndex = -1;

      this.$nextTick(() => {
        this.focusedIndex = 0;
      });
    },
    focusedIndex() {
      if (!this.mouseOver) {
        this.$nextTick(() => {
          if (!this.$refs.virtualScrollList?.$el) {
            return;
          }
          const el = this.$refs.virtualScrollList.$el;
          const scrollTop = this.focusedIndex * FILE_FINDER_ROW_HEIGHT;
          const bottom = this.listShowCount * FILE_FINDER_ROW_HEIGHT;

          if (this.focusedIndex === 0) {
            // if index is the first index, scroll straight to start
            el.scrollTop = 0;
          } else if (this.focusedIndex === this.filteredBlobsLength - 1) {
            // if index is the last index, scroll to the end
            el.scrollTop = this.filteredBlobsLength * FILE_FINDER_ROW_HEIGHT;
          } else if (scrollTop >= bottom + el.scrollTop) {
            // if element is off the bottom of the scroll list, scroll down one item
            el.scrollTop = scrollTop - bottom + FILE_FINDER_ROW_HEIGHT;
          } else if (scrollTop < el.scrollTop) {
            // if element is off the top of the scroll list, scroll up one item
            el.scrollTop = scrollTop;
          }
        });
      }
    },
  },
  mounted() {
    if (this.files.length) {
      this.focusedIndex = 0;
    }

    Mousetrap.bind(keysFor(MR_GO_TO_FILE), (e) => {
      if (e.preventDefault) {
        e.preventDefault();
      }

      this.toggle(!this.visible);
    });

    addStopCallback((e, el, combo) => {
      if (
        (combo === 't' && el.classList.contains('dropdown-input-field')) ||
        el.classList.contains('inputarea')
      ) {
        return true;
      }
      if (combo === 'mod+p') {
        return false;
      }

      return undefined;
    });
  },
  methods: {
    toggle(visible) {
      this.$emit('toggle', visible);
    },
    clearSearchInput() {
      this.searchText = '';

      this.$nextTick(() => {
        this.$refs.searchInput.focus();
      });
    },
    onKeydown(e) {
      switch (e.keyCode) {
        case UP_KEY_CODE:
          e.preventDefault();
          this.mouseOver = false;
          this.cancelMouseOver = true;
          if (this.focusedIndex > 0) {
            this.focusedIndex -= 1;
          } else {
            this.focusedIndex = this.filteredBlobsLength - 1;
          }
          break;
        case DOWN_KEY_CODE:
          e.preventDefault();
          this.mouseOver = false;
          this.cancelMouseOver = true;
          if (this.focusedIndex < this.filteredBlobsLength - 1) {
            this.focusedIndex += 1;
          } else {
            this.focusedIndex = 0;
          }
          break;
        default:
          break;
      }
    },
    onKeyup(e) {
      switch (e.keyCode) {
        case ENTER_KEY_CODE:
          this.openFile(this.filteredBlobs[this.focusedIndex]);
          break;
        case ESC_KEY_CODE:
          this.toggle(false);
          break;
        default:
          break;
      }
    },
    openFile(file) {
      this.toggle(false);
      this.$emit('click', file);
    },
    onMouseOver(index) {
      if (!this.cancelMouseOver) {
        this.mouseOver = true;
        this.focusedIndex = index;
      }
    },
    onMouseMove(index) {
      this.cancelMouseOver = false;
      this.onMouseOver(index);
    },
  },
};
</script>

<template>
  <div
    v-if="visible"
    data-testid="overlay"
    class="file-finder-overlay"
    @mousedown.self="toggle(false)"
  >
    <div class="dropdown-menu diff-file-changes file-finder show">
      <div :class="{ 'has-value': showClearInputButton }" class="dropdown-input">
        <input
          ref="searchInput"
          v-model="searchText"
          :placeholder="__('Search files')"
          type="search"
          class="dropdown-input-field"
          autocomplete="off"
          data-testid="search-input"
          @keydown="onKeydown($event)"
          @keyup="onKeyup($event)"
        />
        <gl-icon
          name="search"
          class="dropdown-input-search"
          :class="{ hidden: showClearInputButton }"
        />
        <gl-icon
          name="close"
          data-testid="clear-search-input"
          class="dropdown-input-clear"
          role="button"
          :aria-label="__('Clear search input')"
          @click="clearSearchInput"
        />
      </div>
      <div>
        <virtual-list ref="virtualScrollList" :size="listHeight" :remain="listShowCount" wtag="ul">
          <template v-if="filteredBlobsLength">
            <li v-for="(file, index) in filteredBlobs" :key="file.key">
              <item
                :file="file"
                :search-text="searchText"
                :focused="index === focusedIndex"
                :index="index"
                :show-diff-stats="showDiffStats"
                class="disable-hover"
                @click="openFile"
                @mouseover="onMouseOver"
                @mousemove="onMouseMove"
              />
            </li>
          </template>
          <li v-else class="dropdown-menu-empty-item">
            <div class="gl-mb-3 gl-ml-3 gl-mr-3 gl-mt-5">
              <template v-if="loading">
                <gl-loading-icon />
              </template>
              <template v-else>
                {{ __('No files found.') }}
              </template>
            </div>
          </li>
        </virtual-list>
      </div>
    </div>
  </div>
</template>

<style scoped>
.file-finder-overlay {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 200;
}

.file-finder {
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
}

.diff-file-changes {
  top: 50px;
  max-height: 327px;
}
</style>
