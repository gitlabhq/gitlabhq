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
    RepoStore.files = RepoHelper.getNewMergedList(inDirectory, currentList, newList);
  },

  toggleRawPreview() {
    RepoStore.activeFile.raw = !RepoStore.activeFile.raw;
    RepoStore.activeFileLabel = RepoStore.activeFile.raw ? 'Display rendered file' : 'Display source';
  },

  setActiveFiles(file) {
    if (RepoStore.isActiveFile(file)) return;

    RepoStore.openedFiles = RepoStore.openedFiles.map((openedFile, i) => RepoStore.w(openedFile, i));

    RepoStore.setActiveToRaw();

    if (file.binary) {
      RepoStore.blobRaw = file.base64;
    } else {
      RepoStore.blobRaw = file.plain;
    }

    if (!file.loading) RepoHelper.toURL(file.url);
    RepoStore.binary = file.binary;
  },

  w(file, i) {
    const activeFile = file;
    activeFile.active = activeFile.url === activeFile.url;

    if (activeFile.active) RepoStore.setActiveFile(activeFile, i);

    return activeFile;
  },

  setActiveFile(activeFile, i) {
    RepoStore.activeFile = activeFile;
    RepoStore.activeFileIndex = i;
  },

  setActiveToRaw() {
    RepoStore.activeFile.raw = false;
    // can't get vue to listen to raw for some reason so RepoStore for now.
    RepoStore.activeFileLabel = 'Display source';
  },

  /* eslint-disable no-param-reassign */
  removeChildFilesOfTree(tree) {
    let foundTree = false;
    RepoStore.files = RepoStore.files.filter((file) => {
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

    RepoStore.openedFiles = RepoStore.openedFiles.filter(openedFile => openedFile.url !== file.url);
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

    RepoStore.openedFiles.push(newFakeFile);

    return newFakeFile;
  },

  addToOpenedFiles(file) {
    const openFile = file;

    const openedFilesAlreadyExists = RepoStore.openedFiles
      .some(openedFile => openedFile.url === openFile.url);

    if (openedFilesAlreadyExists) return;

    openFile.changed = false;
    RepoStore.openedFiles.push(openFile);
  },

  setActiveFileContents(contents) {
    if (!RepoStore.editMode) return;

    RepoStore.activeFile.newContent = contents;
    RepoStore.activeFile.changed = RepoStore.activeFile.plain !== RepoStore.activeFile.newContent;
    RepoStore.openedFiles[RepoStore.activeFileIndex].changed = RepoStore.activeFile.changed;
  },

  // getters

  isActiveFile(file) {
    return file && file.url === RepoStore.activeFile.url;
  },
};
export default RepoStore;
