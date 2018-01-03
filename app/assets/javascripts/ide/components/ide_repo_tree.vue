<script>
import { mapState } from 'vuex';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';
import { treeList } from '../stores/utils';

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
    fetchedList() {
      return treeList(this.$store.state, this.treeId);
    },
    hasPreviousDirectory() {
      return !this.isRoot && this.fetchedList.length;
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
          v-for="file in fetchedList"
          :key="file.key"
          :file="file"
        />
      </tbody>
    </table>
  </div>
</div>
</template>
