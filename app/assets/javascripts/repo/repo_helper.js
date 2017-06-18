let RepoHelper = {
  isTree(data) {
    return data.hasOwnProperty('blobs');
  }
};

export default RepoHelper;