const RepoStore = {
  service: '',
  editor: '',
  sidebar: '',
  editButton: '',
  editMode: false,
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
    url: '',
<<<<<<< HEAD
    raw: false,
    newContent: '',
    changed: false
=======
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
  },
  activeFileIndex: 0,
  activeLine: 0,
  activeFileLabel: 'Raw',
  files: [],
  binary: false,
  binaryMimeType: '',
  // scroll bar space for windows
  scrollWidth: 0,
  binaryTypes: {
    png: false,
    markdown: false,
  },
  loading: {
    tree: false,
    blob: false,
  },
};
export default RepoStore;
