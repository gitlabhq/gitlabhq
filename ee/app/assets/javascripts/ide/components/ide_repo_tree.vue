<script>
import { mapState, mapGetters } from 'vuex';
import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import repoFile from './repo_file.vue';

export default {
  components: {
    repoFile,
    skeletonLoadingContainer,
  },
  props: {
    treeId: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'trees',
    ]),
    ...mapGetters([
      'treeList',
    ]),
    selctedTree() {
      return this.trees[this.treeId].tree;
    },
    showLoading() {
      return !this.trees[this.treeId] || this.trees[this.treeId].loading;
    },
  },
};
</script>

<template>
  <div
    class="ide-file-list"
    v-if="treeId"
  >
    <template v-if="showLoading">
      <div
        class="multi-file-loading-container"
        v-for="n in 3"
        :key="n"
      >
        <skeleton-loading-container />
      </div>
    </template>
    <repo-file
      v-for="file in treeList"
      :key="file.key"
      :file="file"
    />
  </div>
</template>
