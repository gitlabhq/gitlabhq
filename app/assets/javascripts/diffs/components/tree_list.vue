<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowStats from './file_row_stats.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Icon,
    FileRow,
  },
  computed: {
    ...mapState('diffs', ['tree', 'renderTreeList']),
    ...mapGetters('diffs', ['allBlobs']),
    filteredTreeList() {
      return this.renderTreeList ? this.tree : this.allBlobs;
    },
  },
  methods: {
    ...mapActions('diffs', ['toggleTreeOpen', 'scrollToFile', 'toggleFileFinder']),
  },
  shortcutKeyCharacter: `${/Mac/i.test(navigator.userAgent) ? '&#8984;' : 'Ctrl'}+P`,
  FileRowStats,
};
</script>

<template>
  <div class="tree-list-holder d-flex flex-column">
    <div class="append-bottom-8 position-relative tree-list-search d-flex">
      <div class="flex-fill d-flex">
        <icon name="search" class="position-absolute tree-list-icon" />
        <button
          type="button"
          class="form-control text-left text-secondary"
          @click="toggleFileFinder(true)"
        >
          {{ s__('MergeRequest|Search files') }}
        </button>
        <span
          class="position-absolute text-secondary diff-tree-search-shortcut"
          v-html="$options.shortcutKeyCharacter"
        ></span>
      </div>
    </div>
    <div :class="{ 'pt-0 tree-list-blobs': !renderTreeList }" class="tree-list-scroll">
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
      <p v-else class="prepend-top-20 append-bottom-20 text-center">
        {{ s__('MergeRequest|No files found') }}
      </p>
    </div>
  </div>
</template>

<style>
.tree-list-blobs .file-row-name {
  margin-left: 12px;
}

.diff-tree-search-shortcut {
  top: 50%;
  right: 10px;
  transform: translateY(-50%);
  pointer-events: none;
}

.tree-list-icon {
  pointer-events: none;
}
</style>
