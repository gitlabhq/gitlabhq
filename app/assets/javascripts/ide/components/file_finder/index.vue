<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import VirtualList from 'vue-virtual-scroll-list';
import Item from './item.vue';
import router from '../../ide_router';
import {
  MAX_FILE_FINDER_RESULTS,
  FILE_FINDER_ROW_HEIGHT,
  FILE_FINDER_EMPTY_ROW_HEIGHT,
  UP_KEY_CODE,
  DOWN_KEY_CODE,
  ENTER_KEY_CODE,
  ESC_KEY_CODE,
} from '../../constants';

export default {
  components: {
    Item,
    VirtualList,
  },
  data() {
    return {
      focusedIndex: 0,
      searchText: '',
      mouseOver: false,
    };
  },
  computed: {
    ...mapGetters(['allBlobs']),
    ...mapState(['fileFindVisible', 'loading']),
    filteredBlobs() {
      const searchText = this.searchText.trim();

      if (searchText === '') {
        return this.allBlobs.slice(0, MAX_FILE_FINDER_RESULTS);
      }

      return fuzzaldrinPlus
        .filter(this.allBlobs, searchText, {
          key: 'path',
          maxResults: MAX_FILE_FINDER_RESULTS,
        })
        .sort((a, b) => b.lastOpenedAt - a.lastOpenedAt);
    },
    filteredBlobsLength() {
      return this.filteredBlobs.length;
    },
    listShowCount() {
      return this.filteredBlobsLength ? Math.min(this.filteredBlobsLength, 5) : 1;
    },
    listHeight() {
      return this.filteredBlobsLength ? FILE_FINDER_ROW_HEIGHT : FILE_FINDER_EMPTY_ROW_HEIGHT;
    },
    showClearInputButton() {
      return this.searchText.trim() !== '';
    },
  },
  watch: {
    fileFindVisible() {
      this.$nextTick(() => {
        if (!this.fileFindVisible) {
          this.searchText = '';
        } else {
          this.focusedIndex = 0;

          if (this.$refs.searchInput) {
            this.$refs.searchInput.focus();
          }
        }
      });
    },
    searchText() {
      this.focusedIndex = 0;
    },
    focusedIndex() {
      if (!this.mouseOver) {
        this.$nextTick(() => {
          const el = this.$refs.virtualScrollList.$el;

          el.scrollTop = this.focusedIndex * 55;
        });
      }
    },
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
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
          if (this.focusedIndex > 0) {
            this.focusedIndex -= 1;
          } else {
            this.focusedIndex = this.filteredBlobsLength - 1;
          }
          break;
        case DOWN_KEY_CODE:
          e.preventDefault();
          this.mouseOver = false;
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
          this.toggleFileFinder(false);
          break;
        default:
          break;
      }
    },
    openFile(file) {
      this.toggleFileFinder(false);
      router.push(`/project${file.url}`);
    },
    onMouseOver(index) {
      this.mouseOver = true;
      this.focusedIndex = index;
    },
  },
};
</script>

<template>
  <div
    class="ide-file-finder-overlay"
    @mousedown.self="toggleFileFinder(false)"
  >
    <div
      class="dropdown-menu diff-file-changes ide-file-finder show"
    >
      <div class="dropdown-input">
        <input
          type="search"
          class="dropdown-input-field"
          :placeholder="__('Search files')"
          autocomplete="off"
          v-model="searchText"
          ref="searchInput"
          @keydown="onKeydown($event)"
          @keyup="onKeyup($event)"
        />
        <i
          aria-hidden="true"
          class="fa fa-search dropdown-input-search"
          :class="{
            hidden: showClearInputButton
          }"
        ></i>
        <i
          role="button"
          aria-hidden="true"
          class="fa fa-times dropdown-input-clear"
          :class="{
            show: showClearInputButton
          }"
          @click="clearSearchInput"
        ></i>
      </div>
      <div>
        <virtual-list
          :size="listHeight"
          :remain="listShowCount"
          wtag="ul"
          ref="virtualScrollList"
        >
          <template v-if="filteredBlobsLength">
            <li
              v-for="(file, index) in filteredBlobs"
              :key="file.key"
            >
              <item
                :file="file"
                :search-text="searchText"
                :focused="index === focusedIndex"
                :index="index"
                @click="openFile"
                @mouseover="onMouseOver"
              />
            </li>
          </template>
          <li
            v-else
            class="dropdown-menu-empty-itemhidden"
          >
            <a href="#">
              <template v-if="loading">
                {{ __('Loading...') }}
              </template>
              <template v-else>
                {{ __('No files found.') }}
              </template>
            </a>
          </li>
        </virtual-list>
      </div>
    </div>
  </div>
</template>
