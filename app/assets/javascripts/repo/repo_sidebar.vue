<script>
import Service from './repo_service';
import Helper from './repo_helper';
import Store from './repo_store';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFileOptions from './repo_file_options.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';
import RepoMixin from './repo_mixin';

const RepoSidebar = {
  mixins: [RepoMixin],
  components: {
    'repo-file-options': RepoFileOptions,
    'repo-previous-directory': RepoPreviousDirectory,
    'repo-file': RepoFile,
    'repo-loading-file': RepoLoadingFile,
  },

  created() {
    this.addPopEventListener();
  },

  data: () => Store,

  methods: {
    addPopEventListener() {
      window.addEventListener('popstate', () => {
        if (location.href.indexOf('#') > -1) return;
        this.linkClicked({
          url: location.href,
        });
      });
    },

    linkClicked(clickedFile) {
      let url = '';
      let file = clickedFile;
      if (typeof file === 'object') {
        file.loading = true;
        if (file.type === 'tree' && file.opened) {
          file = Store.removeChildFilesOfTree(file);
          file.loading = false;
        } else {
          url = file.url;
          Service.url = url;
          // I need to refactor this to do the `then` here.
          // Not a callback. For now this is good enough.
          // it works.
          Helper.getContent(file, () => {
            file.loading = false;
            Helper.scrollTabsRight();
          });
        }
      } else if (typeof file === 'string') {
        // go back
        url = file;
        Service.url = url;
        Helper.getContent(null, () => {
          Helper.scrollTabsRight();
        });
      }
    },
  },
};

export default RepoSidebar;
</script>

<template>
<div id="sidebar" :class="{'sidebar-mini' : isMini}" v-cloak>
  <table class="table">
    <thead v-if="!isMini">
      <tr>
        <th class="name">Name</th>
        <th class="hidden-sm hidden-xs last-commit">Last Commit</th>
        <th class="hidden-xs last-update">Last Update</th>
      </tr>
    </thead>
    <tbody>
      <repo-file-options
        :is-mini="isMini"
        :project-name="projectName"/>
      <repo-previous-directory
        v-if="isRoot"
        :prev-url="prevURL"
        @linkclicked="linkClicked(prevURL)"/>
      <repo-loading-file
        v-for="n in 5"
        :key="n"
        :loading="loading"
        :has-files="!!files.length"
        :is-mini="isMini"/>
      <repo-file
        v-for="file in files"
        :key="file.id"
        :file="file"
        :is-mini="isMini"
        @linkclicked="linkClicked(file)"
        :is-tree="isTree"
        :has-files="!!files.length"
        :active-file="activeFile"/>
    </tbody>
  </table>
</div>
</template>
