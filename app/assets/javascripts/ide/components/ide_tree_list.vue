<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import FileTree from '~/vue_shared/components/file_tree.vue';
import { WEBIDE_MARK_FILE_CLICKED } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import IdeFileRow from './ide_file_row.vue';
import NavDropdown from './nav_dropdown.vue';

export default {
  name: 'IdeTreeList',
  components: {
    GlSkeletonLoading,
    NavDropdown,
    FileTree,
  },
  props: {
    headerClass: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'currentTree']),
    showLoading() {
      return !this.currentTree || this.currentTree.loading;
    },
  },
  watch: {
    showLoading(newVal) {
      if (!newVal) {
        this.$emit('tree-ready');
      }
    },
  },
  methods: {
    ...mapActions(['toggleTreeOpen']),
    clickedFile() {
      performanceMarkAndMeasure({ mark: WEBIDE_MARK_FILE_CLICKED });
    },
  },
  IdeFileRow,
};
</script>

<template>
  <div class="ide-file-list qa-file-list">
    <template v-if="showLoading">
      <div v-for="n in 3" :key="n" class="multi-file-loading-container">
        <gl-skeleton-loading />
      </div>
    </template>
    <template v-else>
      <header :class="headerClass" class="ide-tree-header">
        <nav-dropdown />
        <slot name="header"></slot>
      </header>
      <div class="ide-tree-body h-100" data-testid="ide-tree-body">
        <template v-if="currentTree.tree.length">
          <file-tree
            v-for="file in currentTree.tree"
            :key="file.key"
            :file="file"
            :level="0"
            :file-row-component="$options.IdeFileRow"
            @toggleTreeOpen="toggleTreeOpen"
            @clickFile="clickedFile"
          />
        </template>
        <div v-else class="file-row">{{ __('No files') }}</div>
      </div>
    </template>
  </div>
</template>
