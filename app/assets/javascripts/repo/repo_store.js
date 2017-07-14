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
  activeFile: {
    active: true,
    binary: false,
    extension: '',
    html: '',
    mime_type: '',
    name: 'loading...',
    plain: '',
    size: 0,
    url: ''
  },
  activeLine: 0,
  files: [],
  binary: false,
  binaryMimeType: '',
  //scroll bar space for windows
  scrollWidth: 0,
  binaryTypes: {
    png: false,
    markdown: false
  },
  loading: {
    tree: false,
    blob: false
  }
};
export default RepoStore;
