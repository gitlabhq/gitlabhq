<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import NavDropdown from './nav_dropdown.vue';
import FileRowExtra from './file_row_extra.vue';

export default {
  components: {
    Icon,
    SkeletonLoadingContainer,
    NavDropdown,
    FileRow,
  },
  props: {
    viewerType: {
      type: String,
      required: true,
    },
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
  mounted() {
    this.updateViewer(this.viewerType);
  },
  methods: {
    ...mapActions(['updateViewer', 'toggleTreeOpen']),
  },
  FileRowExtra,
};
</script>

<template>
  <div
    class="ide-file-list"
  >
    <template v-if="showLoading">
      <div
        v-for="n in 3"
        :key="n"
        class="multi-file-loading-container"
      >
        <skeleton-loading-container />
      </div>
    </template>
    <template v-else>
      <header
        :class="headerClass"
        class="ide-tree-header"
      >
        <nav-dropdown />
        <slot name="header"></slot>
      </header>
      <div
        class="ide-tree-body h-100"
      >
        <file-row
          v-for="file in currentTree.tree"
          :key="file.key"
          :file="file"
          :level="0"
          :extra-component="$options.FileRowExtra"
          @toggleTreeOpen="toggleTreeOpen"
        />
      </div>
    </template>
  </div>
</template>
