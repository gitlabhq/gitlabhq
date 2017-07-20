import RepoHelper from './repo_helper';

const RepoStore = {
  ideEl: {},
  monacoInstance: {},
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
    raw: false,
    newContent: '',
    changed: false,
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

  // mutations

  addFilesToDirectory(inDirectory, currentList, newList) {
    this.files = RepoHelper.getNewMergedList(inDirectory, currentList, newList);
  },

  toggleRawPreview() {
    this.activeFile.raw = !this.activeFile.raw;
    this.activeFileLabel = this.activeFile.raw ? 'Display rendered file' : 'Display source';
  },

  setActiveFiles(file) {
    if (this.isActiveFile(file)) return;

    this.openedFiles = this.openedFiles.map((openedFile, i) => this.setFileToActive(openedFile, i));

    this.setActiveToRaw();

    if (file.binary) {
      this.blobRaw = file.base64;
    } else {
      this.blobRaw = file.plain;
    }

    if (!file.loading) RepoHelper.toURL(file.url);
    this.binary = file.binary;
  },

  setFileToActive(file, i) {
    const activeFile = file;
    activeFile.active = activeFile.url === activeFile.url;

    if (activeFile.active) this.setActiveFile(activeFile, i);

    return activeFile;
  },

  setActiveFile(activeFile, i) {
    this.activeFile = activeFile;
    this.activeFileIndex = i;
  },

  setActiveToRaw() {
    this.activeFile.raw = false;
    // can't get vue to listen to raw for some reason so this for now.
    this.activeFileLabel = 'Display source';
  },

  /* eslint-disable no-param-reassign */
  removeChildFilesOfTree(tree) {
    let foundTree = false;
    this.files = this.files.filter((file) => {
      if (file.url === tree.url) foundTree = true;

      if (foundTree) return file.level <= tree.level;
      return true;
    });

    tree.opened = false;
    tree.icon = 'fa-folder';
  },
  /* eslint-enable no-param-reassign */

  removeFromOpenedFiles(file) {
    if (file.type === 'tree') return;

    this.openedFiles = this.openedFiles.filter(openedFile => openedFile.url !== file.url);
  },

  addPlaceholderFile() {
    const randomURL = RepoHelper.Time.now();
    const newFakeFile = {
      active: false,
      binary: true,
      type: 'blob',
      loading: true,
      mime_type: 'loading',
      name: 'loading',
      url: randomURL,
    };

    this.openedFiles.push(newFakeFile);

    return newFakeFile;
  },

  addToOpenedFiles(file) {
    const openFile = file;

    const openedFilesAlreadyExists = this.openedFiles
      .some(openedFile => openedFile.url === openFile.url);

    if (openedFilesAlreadyExists) return;

    openFile.changed = false;
    this.openedFiles.push(openFile);
  },

  setActiveFileContents(contents) {
    if (!this.editMode) return;

    this.activeFile.newContent = contents;
    this.activeFile.changed = this.activeFile.plain !== this.activeFile.newContent;
    this.openedFiles[this.activeFileIndex].changed = this.activeFile.changed;
  },

  // getters

  isActiveFile(file) {
    return file && file.url === this.activeFile.url;
  },
};
export default RepoStore;
