import Store from '../stores/repo_store';

const RepoMixin = {
  computed: {
    isMini() {
      return !!Store.openedFiles.length;
    },

    changedFiles() {
      const changedFileList = this.openedFiles
      .filter(file => file.changed);
      return changedFileList;
    },
  },
};

export default RepoMixin;
