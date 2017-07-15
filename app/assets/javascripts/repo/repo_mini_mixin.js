import Store from './repo_store';

const RepoMiniMixin = {
  computed: {
    isMini() {
      return !!Store.openedFiles.length;
    },
  },
};

export default RepoMiniMixin;
