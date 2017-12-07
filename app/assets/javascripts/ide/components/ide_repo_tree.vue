<script>
import { mapState, mapGetters } from 'vuex';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';

export default {
  components: {
    'repo-previous-directory': RepoPreviousDirectory,
    'repo-file': RepoFile,
    'repo-loading-file': RepoLoadingFile,
  },
  props: {
    treeId: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'loading',
      'isRoot',
    ]),
    ...mapState({
      projectName(state) {
        return state.project.name;
      },
    }),
    ...mapGetters([
      'treeList',
    ]),
    hasPreviousDirectory() {
      return !this.isRoot && this.treeList(this.treeId).length;
    },
    showLoading() {
      return this.loading;
    },
  },
};
</script>

<template>
<div>
  <div class="ide-file-list">
    <table class="table">
      <tbody
        v-if="treeId">
        <repo-previous-directory
          v-if="hasPreviousDirectory"
        />
        <repo-loading-file
          v-if="showLoading"
          v-for="n in 5"
          :key="n"
        />
        <repo-file
          v-for="file in treeList(treeId)"
          :key="file.key"
          :file="file"
        />
      </tbody>
    </table>
  </div>
</div>
</template>
