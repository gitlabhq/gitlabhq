<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from './file_row_stats.vue';

export default {
  components: {
    Icon,
    FileRow,
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapState('diffs', ['tree', 'addedLines', 'removedLines']),
    ...mapGetters('diffs', ['allBlobs', 'diffFilesLength']),
    filteredTreeList() {
      const search = this.search.toLowerCase().trim();

      if (search === '') return this.tree;

      return this.allBlobs.filter(f => f.name.toLowerCase().indexOf(search) >= 0);
    },
  },
  methods: {
    ...mapActions('diffs', ['toggleTreeOpen', 'scrollToFile']),
    clearSearch() {
      this.search = '';
    },
  },
  FileRowStats,
};
</script>

<template>
  <div class="tree-list-holder d-flex flex-column">
    <div class="append-bottom-8 position-relative tree-list-search">
      <icon
        name="search"
        class="position-absolute tree-list-icon"
      />
      <input
        v-model="search"
        :placeholder="s__('MergeRequest|Filter files')"
        type="search"
        class="form-control"
      />
      <button
        v-show="search"
        :aria-label="__('Clear search')"
        type="button"
        class="position-absolute tree-list-icon tree-list-clear-icon border-0 p-0"
        @click="clearSearch"
      >
        <icon
          name="close"
        />
      </button>
    </div>
    <div
      class="tree-list-scroll"
    >
      <template v-if="filteredTreeList.length">
        <file-row
          v-for="file in filteredTreeList"
          :key="file.key"
          :file="file"
          :level="0"
          :hide-extra-on-tree="true"
          :extra-component="$options.FileRowStats"
          :show-changed-icon="true"
          @toggleTreeOpen="toggleTreeOpen"
          @clickFile="scrollToFile"
        />
      </template>
      <p
        v-else
        class="prepend-top-20 append-bottom-20 text-center"
      >
        {{ s__('MergeRequest|No files found') }}
      </p>
    </div>
    <div
      v-once
      class="pt-3 pb-3 text-center"
    >
      {{ n__('%d changed file', '%d changed files', diffFilesLength) }}
      <div>
        <span class="cgreen">
          {{ n__('%d addition', '%d additions', addedLines) }}
        </span>
        <span class="cred">
          {{ n__('%d deleted', '%d deletions', removedLines) }}
        </span>
      </div>
    </div>
  </div>
</template>
