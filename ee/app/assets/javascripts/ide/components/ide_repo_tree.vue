<script>
import { mapState } from 'vuex';
import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import repoPreviousDirectory from './repo_prev_directory.vue';
import repoFile from './repo_file.vue';
import { treeList } from '../stores/utils';

export default {
  components: {
    repoPreviousDirectory,
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
      'isRoot',
    ]),
    ...mapState({
      projectName(state) {
        return state.project.name;
      },
    }),
    fetchedList() {
      return treeList(this.$store.state, this.treeId);
    },
    hasPreviousDirectory() {
      return !this.isRoot && this.fetchedList.length;
    },
    showLoading() {
      if (this.trees[this.treeId]) {
        return this.trees[this.treeId].loading;
      }
      return true;
    },
  },
};
</script>

<template>
  <div>
    <div class="ide-file-list">
      <table class="table">
        <tbody
          v-if="treeId"
        >
          <repo-previous-directory
            v-if="hasPreviousDirectory"
          />
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
            v-for="file in fetchedList"
            :key="file.key"
            :file="file"
          />
        </tbody>
      </table>
    </div>
  </div>
</template>
