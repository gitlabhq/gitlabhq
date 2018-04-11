<script>
import { mapGetters, mapState } from 'vuex';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import VirtualList from 'vue-virtual-scroll-list';
import Item from './item.vue';

export default {
  components: {
    Item,
    VirtualList,
  },
  data() {
    return {
      searchText: '',
    };
  },
  computed: {
    ...mapGetters(['allBlobs']),
    ...mapState(['loading']),
    filteredBlobs() {
      const searchText = this.searchText.trim();

      if (searchText === '') return this.allBlobs;

      return fuzzaldrinPlus.filter(this.allBlobs, searchText, {
        key: 'path',
      });
    },
    listShowCount() {
      if (this.filteredBlobs.length === 0) return 1;

      return this.filteredBlobs.length > 5 ? 5 : this.filteredBlobs.length;
    },
    listHeight() {
      return this.listShowCount > 1 ? 55 : 33;
    },
  },
  mounted() {
    this.$refs.searchInput.focus();
  },
};
</script>

<template>
  <div class="dropdown-menu diff-file-changes ide-file-finder" style="display: block;">
    <div class="dropdown-input">
      <input
        type="search"
        class="dropdown-input-field"
        placeholder="Search files"
        autocomplete="off"
        v-model="searchText"
        ref="searchInput"
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
        wtag="ul"
      >
        <template v-if="filteredBlobs.length">
          <li
            v-for="file in filteredBlobs"
            :key="file.key"
          >
            <item
              :file="file"
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
</template>

<style>
.ide-file-finder {
  top: 100px;
  left: 50%;
  transform: translateX(-50%);
}
</style>
