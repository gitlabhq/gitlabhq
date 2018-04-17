<script>
import { mapGetters, mapState } from 'vuex';
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
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'currentTree']),
  },
};
</script>

<template>
  <div
    v-if="currentTree"
    class="ide-file-list"
  >
    <template v-if="currentTree.loading">
      <div
        class="multi-file-loading-container"
        v-for="n in 3"
        :key="n"
      >
        <skeleton-loading-container />
      </div>
    </template>
    <template v-else>
      <header class="ide-tree-header">
        {{ __('Edit') }}
        <new-dropdown
          :project-id="currentProject.name_with_namespace"
          :branch="currentBranchId"
          path=""
        />
      </header>
      <repo-file
        v-for="file in currentTree.tree"
        :key="file.key"
        :file="file"
        :level="0"
      />
    </template>
  </div>
</template>
