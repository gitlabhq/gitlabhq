<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import VirtualList from 'vue-virtual-scroll-list';
import Item from './item.vue';
import router from '../../ide_router';

const MAX_RESULTS = 20;

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

      if (searchText === '') return this.allBlobs.slice(0, MAX_RESULTS);

      return fuzzaldrinPlus.filter(this.allBlobs, searchText, {
        key: 'path',
        maxResults: MAX_RESULTS,
      });
    },
    listShowCount() {
      if (!this.filteredBlobs.length) return 1;

      return this.filteredBlobs.length > 5 ? 5 : this.filteredBlobs.length;
    },
    listHeight() {
      return this.filteredBlobs.length ? 55 : 33;
    },
  },
  watch: {
    fileFindVisible() {
      this.$nextTick(() => this.$refs.searchInput.focus());
    },
    searchText() {
      if (this.searchText.trim() !== '') {
        this.focusedIndex = 0;
      }
    },
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
    onKeydown(e) {
      switch (e.keyCode) {
        case 38:
          // UP
          e.preventDefault();
          if (this.focusedIndex > 0) this.focusedIndex -= 1;
          break;
        case 40:
          // DOWN
          e.preventDefault();
          if (this.focusedIndex < this.filteredBlobs.length - 1) this.focusedIndex += 1;
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
    @click.self="toggleFileFinder(false)"
  >
    <div
      class="dropdown-menu diff-file-changes ide-file-finder show"
    >
      <div class="dropdown-input">
        <input
          type="search"
          class="dropdown-input-field"
          placeholder="Search files"
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
          <template v-if="filteredBlobs.length">
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
            <a href="">
              <template v-if="loading">
                Loading...
              </template>
              <template v-else>
                No files found.
              </template>
            </a>
          </li>
        </virtual-list>
      </div>
    </div>
  </div>
</template>

<style>
.ide-file-finder-overlay {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 100;
}

.ide-file-finder {
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
}
</style>
