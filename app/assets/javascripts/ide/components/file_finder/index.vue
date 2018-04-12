<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import VirtualList from 'vue-virtual-scroll-list';
import Item from './item.vue';
import router from '../../ide_router';

const MAX_RESULTS = 40;

export default {
  components: {
    Item,
    VirtualList,
  },
  data() {
    return {
      focusedIndex: 0,
      searchText: '',
    };
  },
  computed: {
    ...mapGetters(['allBlobs']),
    ...mapState(['fileFindVisible', 'loading']),
    filteredBlobs() {
      const searchText = this.searchText.trim();

      if (searchText === '')
        return this.allBlobs.sort((a, b) => b.lastOpenedAt - a.lastOpenedAt).slice(0, MAX_RESULTS);

      return fuzzaldrinPlus.filter(this.allBlobs, searchText, {
        key: 'path',
        maxResults: MAX_RESULTS,
      });
    },
    filteredBlobsLength() {
      return this.filteredBlobs.length;
    },
    listShowCount() {
      if (!this.filteredBlobsLength) return 1;

      return this.filteredBlobsLength > 5 ? 5 : this.filteredBlobsLength;
    },
    listHeight() {
      return this.filteredBlobsLength ? 55 : 33;
    },
  },
  watch: {
    fileFindVisible() {
      this.$nextTick(() => {
        if (!this.fileFindVisible) {
          this.searchText = '';
        } else {
          this.focusedIndex = 0;

          this.$refs.searchInput.focus();
        }
      });
    },
    searchText() {
      this.focusedIndex = 0;
    },
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
    onKeydown(e) {
      switch (e.keyCode) {
        case 38:
          // UP
          e.preventDefault();
          if (this.focusedIndex > 0) {
            this.focusedIndex -= 1;
          } else {
            this.focusedIndex = this.filteredBlobsLength - 1;
          }
          break;
        case 40:
          // DOWN
          e.preventDefault();
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
        case 13:
          // ENTER
          this.openFile(this.filteredBlobs[this.focusedIndex]);
          break;
        case 27:
          // ESC
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
        ></i>
      </div>
      <div>
        <virtual-list
          :size="listHeight"
          :remain="listShowCount"
          :start="focusedIndex"
          wtag="ul"
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
                @click="openFile"
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
