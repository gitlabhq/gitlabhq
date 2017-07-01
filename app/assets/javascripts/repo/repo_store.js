let RepoStore = {
  service: '',
  editor: '',
  sidebar: '',
  isTree: false,
  prevURL: '',
  trees: [],
  blobs: [],
  submodules: [],
  blobRaw: '',
  blobRendered: '',
  openedFiles: [],
  activeFile: '',
  files: [],
  binary: false,
  binaryMimeType: '',
  binaryTypes: {
    png: false
  }
};
export default RepoStore;
