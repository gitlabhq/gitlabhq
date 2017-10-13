<script>
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';
import Store from '../stores/repo_store';
import eventHub from '../event_hub';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';
import RepoMixin from '../mixins/repo_mixin';

export default {
  mixins: [RepoMixin],
  components: {
    'repo-previous-directory': RepoPreviousDirectory,
    'repo-file': RepoFile,
    'repo-loading-file': RepoLoadingFile,
  },
  created() {
    window.addEventListener('popstate', this.checkHistory);
  },
  destroyed() {
    eventHub.$off('linkclicked', this.fileClicked);
    eventHub.$off('goToPreviousDirectoryClicked', this.goToPreviousDirectoryClicked);
    window.removeEventListener('popstate', this.checkHistory);
  },
  mounted() {
    eventHub.$on('linkclicked', this.fileClicked);
    eventHub.$on('goToPreviousDirectoryClicked', this.goToPreviousDirectoryClicked);
  },
  data: () => Store,
  computed: {
    flattendFiles() {
      const map = (arr) => {
        if (arr && arr.tree.length === 0) {
          return [];
        }

        return _.map(arr.tree, a => [a, map(a)]);
      };

      return _.chain(this.files)
        .map(arr => [arr, map(arr)])
        .flatten()
        .value();
    },
  },
  methods: {
    checkHistory() {
      let selectedFile = this.files.find(file => location.pathname.indexOf(file.url) > -1);
      if (!selectedFile) {
        // Maybe it is not in the current tree but in the opened tabs
        selectedFile = Helper.getFileFromPath(location.pathname);
      }

      let lineNumber = null;
      if (location.hash.indexOf('#L') > -1) lineNumber = Number(location.hash.substr(2));

      if (selectedFile) {
        if (selectedFile.url !== this.activeFile.url) {
          this.fileClicked(selectedFile, lineNumber);
        } else {
          Store.setActiveLine(lineNumber);
        }
      } else {
        // Not opened at all lets open new tab
        this.fileClicked({
          url: location.href,
        }, lineNumber);
      }
    },

    fileClicked(clickedFile, lineNumber) {
      const file = clickedFile;

      if (file.loading) return;

      if (file.type === 'tree' && file.opened) {
        Helper.setDirectoryToClosed(file);
        Store.setActiveLine(lineNumber);
      } else {
        const openFile = Helper.getFileFromPath(file.url);
        file.loading = true;

        if (openFile) {
          file.loading = false;
          Store.setActiveFiles(openFile);
          Store.setActiveLine(lineNumber);
        } else {
          Service.url = file.url;
          Helper.getContent(file)
            .then(() => {
              file.loading = false;
              Helper.scrollTabsRight();
              Store.setActiveLine(lineNumber);
            })
            .catch(Helper.loadingError);
        }
      }
    },

    goToPreviousDirectoryClicked(prevURL) {
      Service.url = prevURL;
      Helper.getContent(null)
        .then(() => Helper.scrollTabsRight())
        .catch(Helper.loadingError);
    },
  },
};
</script>

<template>
<div id="sidebar" :class="{'sidebar-mini' : isMini}">
  <table class="table">
    <thead>
      <tr>
        <th
          v-if="isMini"
          class="repo-file-options title"
        >
          <strong class="clgray">
            {{ projectName }}
          </strong>
        </th>
        <template v-else>
          <th class="name">
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
        v-if="!isRoot"
        :prev-url="prevURL"
      />
      <repo-loading-file
        v-if="!flattendFiles.length && loading.tree"
        v-for="n in 5"
        :key="n"
      />
      <repo-file
        v-for="file in flattendFiles"
        :key="file.id"
        :file="file"
      />
    </tbody>
  </table>
</div>
</template>
