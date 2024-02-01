<script>
import { GlSkeletonLoader } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { WEBIDE_MARK_FILE_CLICKED } from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import FileTree from '~/vue_shared/components/file_tree.vue';
import IdeFileRow from './ide_file_row.vue';
import NavDropdown from './nav_dropdown.vue';

export default {
  name: 'IdeTreeList',
  components: {
    GlSkeletonLoader,
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
    showLoading() {
      this.notifyTreeReady();
    },
  },
  mounted() {
    this.notifyTreeReady();
  },
  methods: {
    ...mapActions(['toggleTreeOpen']),
    notifyTreeReady() {
      if (!this.showLoading) {
        this.$emit('tree-ready');
      }
    },
    clickedFile() {
      performanceMarkAndMeasure({ mark: WEBIDE_MARK_FILE_CLICKED });
    },
  },
  IdeFileRow,
};
</script>

<template>
  <div class="ide-file-list">
    <template v-if="showLoading">
      <div v-for="n in 3" :key="n" class="multi-file-loading-container">
        <gl-skeleton-loader />
      </div>
    </template>
    <template v-else>
      <header :class="headerClass" class="ide-tree-header">
        <nav-dropdown />
        <slot name="header"></slot>
      </header>
      <div class="ide-tree-body gl-h-full" data-testid="ide-tree-body">
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
