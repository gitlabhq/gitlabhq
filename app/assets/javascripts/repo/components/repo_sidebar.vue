<script>
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';
import Store from '../stores/repo_store';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFileOptions from './repo_file_options.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';
import RepoMixin from '../mixins/repo_mixin';

export default {
  mixins: [RepoMixin],
  components: {
    'repo-file-options': RepoFileOptions,
    'repo-previous-directory': RepoPreviousDirectory,
    'repo-file': RepoFile,
    'repo-loading-file': RepoLoadingFile,
  },

  created() {
    window.addEventListener('popstate', this.checkHistory);
  },
  destroyed() {
    window.removeEventListener('popstate', this.checkHistory);
  },

  data: () => Store,

  methods: {
    checkHistory() {
      let selectedFile = this.files.find(file => location.pathname.indexOf(file.url) > -1);
      if (!selectedFile) {
        // Maybe it is not in the current tree but in the opened tabs
        selectedFile = Store.openedFiles.find(file => location.pathname.indexOf(file.url) > -1);
      }
      if (selectedFile) {
        if (selectedFile.url !== this.activeFile.url) {
          this.fileClicked(selectedFile);
        }

        if (location.hash.indexOf('#L') > -1) {
          const lineNumber = Number(location.hash.substr(2));
          if (!isNaN(lineNumber)) {
            Store.setActiveLine(lineNumber);
            if (Store.isPreviewView()) {
              document.getElementById(`L${lineNumber}`).scrollIntoView();
            } else {
              Helper.monacoInstance.setPosition({
                lineNumber: this.activeLine,
                column: 1,
              });
            }
          }
        }
      } else {
        // Not opened at all lets open new tab
        this.fileClicked({
          url: location.href,
        });
      }
    },

    fileClicked(clickedFile) {
      let file = clickedFile;
      if (file.loading) return;
      file.loading = true;

      if (file.type === 'tree' && file.opened) {
        file = Store.removeChildFilesOfTree(file);
        file.loading = false;
      } else {
        const openFile = Helper.getFileFromPath(file.url);
        if (openFile) {
          file.loading = false;
          Store.setActiveFiles(openFile);
        } else {
          Service.url = file.url;
          Helper.getContent(file)
            .then(() => {
              file.loading = false;
              Helper.scrollTabsRight();
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
    <thead v-if="!isMini">
      <tr>
        <th class="name">Name</th>
        <th class="hidden-sm hidden-xs last-commit">Last Commit</th>
        <th class="hidden-xs last-update text-right">Last Update</th>
      </tr>
    </thead>
    <tbody>
      <repo-file-options
        :is-mini="isMini"
        :project-name="projectName"
      />
      <repo-previous-directory
        v-if="isRoot"
        :prev-url="prevURL"
        @linkclicked="goToPreviousDirectoryClicked(prevURL)"/>
      <repo-loading-file
        v-for="n in 5"
        :key="n"
        :loading="loading"
        :has-files="!!files.length"
        :is-mini="isMini"
      />
      <repo-file
        v-for="file in files"
        :key="file.id"
        :file="file"
        :is-mini="isMini"
        @linkclicked="fileClicked(file)"
        :is-tree="isTree"
        :has-files="!!files.length"
        :active-file="activeFile"
      />
    </tbody>
  </table>
</div>
</template>
