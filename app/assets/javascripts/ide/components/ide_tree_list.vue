<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import RepoFile from './repo_file.vue';
import NewDropdown from './new_dropdown/index.vue';

export default {
  components: {
    Icon,
    RepoFile,
    SkeletonLoadingContainer,
    NewDropdown,
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
    disableActionDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'currentTree']),
  },
  mounted() {
    this.updateViewer(this.viewerType);
  },
  methods: {
    ...mapActions(['updateViewer']),
  },
};
</script>

<template>
  <div
    class="ide-file-list"
  >
    <template v-if="!currentTree || currentTree.loading">
      <div
        class="multi-file-loading-container"
        v-for="n in 3"
        :key="n"
      >
        <skeleton-loading-container />
      </div>
    </template>
    <template v-else>
      <header
        class="ide-tree-header"
        :class="headerClass"
      >
        <slot name="header"></slot>
      </header>
      <repo-file
        v-for="file in currentTree.tree"
        :key="file.key"
        :file="file"
        :level="0"
        :disable-action-dropdown="disableActionDropdown"
      />
    </template>
  </div>
</template>
