let RepoHelper = {
  isTree(data) {
    return data.hasOwnProperty('blobs');
  },

  blobURLtoParent(url) {
    const split = url.split('/');
    split.pop();
    const blobIndex = split.indexOf('blob');
    if(blobIndex > -1) {
      split[blobIndex] = 'tree';
    }
    return split.join('/');
  }
};

export default RepoHelper;