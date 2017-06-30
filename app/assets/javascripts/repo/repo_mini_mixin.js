import Store from './repo_store'

let RepoMiniMixin = {
  computed: {
    isMini() {
      return !!Store.openedFiles.length;
    }
  },
};

export default RepoMiniMixin;