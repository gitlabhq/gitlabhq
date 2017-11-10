<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';

export default {
  components: {
    'repo-previous-directory': RepoPreviousDirectory,
    'repo-file': RepoFile,
    'repo-loading-file': RepoLoadingFile,
  },
  created() {
    window.addEventListener('popstate', this.popHistoryState);
  },
  destroyed() {
    window.removeEventListener('popstate', this.popHistoryState);
  },
  mounted() {
    this.getTreeData();
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
      'isCollapsed',
    ]),
  },
  methods: {
    ...mapActions([
      'getTreeData',
      'popHistoryState',
    ]),
  },
};
</script>

<template>
<div id="sidebar" :class="{'sidebar-mini' : isCollapsed}">
  <table class="table">
    <thead>
      <tr>
        <th
          v-if="isCollapsed"
          class="repo-file-options title"
        >
          <strong class="clgray">
            {{ projectName }}
          </strong>
        </th>
        <template v-else>
          <th class="name multi-file-table-col-name">
            Name
          </th>
          <th class="hidden-sm hidden-xs last-commit">
            Last commit
          </th>
          <th class="hidden-xs last-update text-right">
            Last update
          </th>
        </template>
      </tr>
    </thead>
    <tbody>
      <repo-previous-directory
        v-if="!isRoot && treeList.length"
      />
      <repo-loading-file
        v-if="!treeList.length && loading"
        v-for="n in 5"
        :key="n"
      />
      <repo-file
        v-for="(file, index) in treeList"
        :key="file.key"
        :file="file"
      />
    </tbody>
  </table>
</div>
</template>
