import Store from './repo_store'

let RepoMiniMixin = {
  computed: {
    isMini() {
      console.log('checking', Store.openedFiles.length)
      return !!Store.openedFiles.length;
    }
  },
};

export default RepoMiniMixin;