<script>
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import RepoFile from './repo_file.vue';

export default {
  components: {
    RepoFile,
    SkeletonLoadingContainer,
  },
  props: {
    tree: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="ide-file-list"
  >
    <template v-if="tree.loading">
      <div
        class="multi-file-loading-container"
        v-for="n in 3"
        :key="n"
      >
        <skeleton-loading-container />
      </div>
    </template>
    <template v-else>
      <repo-file
        v-for="file in tree.tree"
        :key="file.key"
        :file="file"
        :level="0"
      />
    </template>
  </div>
</template>
