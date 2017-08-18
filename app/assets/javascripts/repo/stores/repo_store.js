/* global Flash */
import Helper from '../helpers/repo_helper';
import Service from '../services/repo_service';

const RepoStore = {
  monaco: {},
  monacoLoading: false,
  service: '',
  canCommit: false,
  onTopOfBranch: false,
  editMode: false,
  isTree: false,
  isRoot: false,
  prevURL: '',
  projectId: '',
  projectName: '',
  projectUrl: '',
  blobRaw: '',
  currentBlobView: 'repo-preview',
  openedFiles: [],
  submitCommitsLoading: false,
  dialog: {
    open: false,
    title: '',
    status: false,
  },
  activeFile: Helper.getDefaultActiveFile(),
  activeFileIndex: 0,
  activeLine: 0,
  activeFileLabel: 'Raw',
  files: [],
  isCommitable: false,
  binary: false,
  currentBranch: '',
  targetBranch: 'new-branch',
  commitMessage: '',
  binaryTypes: {
    png: false,
    md: false,
    svg: false,
    unknown: false,
  },
  loading: {
    tree: false,
    blob: false,
  },

  resetBinaryTypes() {
    Object.keys(RepoStore.binaryTypes).forEach((key) => {
      RepoStore.binaryTypes[key] = false;
    });
  },

  // mutations
  checkIsCommitable() {
    RepoStore.isCommitable = RepoStore.onTopOfBranch && RepoStore.canCommit;
  },

  addFilesToDirectory(inDirectory, currentList, newList) {
    RepoStore.files = Helper.getNewMergedList(inDirectory, currentList, newList);
  },

  toggleRawPreview() {
    RepoStore.activeFile.raw = !RepoStore.activeFile.raw;
    RepoStore.activeFileLabel = RepoStore.activeFile.raw ? 'Display rendered file' : 'Display source';
  },

  setActiveFiles(file) {
    if (RepoStore.isActiveFile(file)) return;
    RepoStore.openedFiles = RepoStore.openedFiles
      .map((openedFile, i) => RepoStore.setFileActivity(file, openedFile, i));

    RepoStore.setActiveToRaw();

    if (file.binary) {
      RepoStore.blobRaw = file.base64;
    } else if (file.newContent || file.plain) {
      RepoStore.blobRaw = file.newContent || file.plain;
    } else {
      Service.getRaw(file.raw_path)
        .then((rawResponse) => {
          RepoStore.blobRaw = rawResponse.data;
          Helper.findOpenedFileFromActive().plain = rawResponse.data;
        }).catch(Helper.loadingError);
    }

    if (!file.loading) Helper.updateHistoryEntry(file.url, file.name);
    RepoStore.binary = file.binary;
  },

  setFileActivity(file, openedFile, i) {
    const activeFile = openedFile;
    activeFile.active = file.url === activeFile.url;

    if (activeFile.active) RepoStore.setActiveFile(activeFile, i);

    return activeFile;
  },

  setActiveFile(activeFile, i) {
    RepoStore.activeFile = Object.assign({}, RepoStore.activeFile, activeFile);
    RepoStore.activeFileIndex = i;
  },

  setActiveToRaw() {
    RepoStore.activeFile.raw = false;
    // can't get vue to listen to raw for some reason so RepoStore for now.
    RepoStore.activeFileLabel = 'Display source';
  },

  removeChildFilesOfTree(tree) {
    let foundTree = false;
    const treeToClose = tree;
    let canStopSearching = false;
    RepoStore.files = RepoStore.files.filter((file) => {
      const isItTheTreeWeWant = file.url === treeToClose.url;
      // if it's the next tree
      if (foundTree && file.type === 'tree' && !isItTheTreeWeWant && file.level === treeToClose.level) {
        canStopSearching = true;
        return true;
      }
      if (canStopSearching) return true;

      if (isItTheTreeWeWant) foundTree = true;

      if (foundTree) return file.level <= treeToClose.level;
      return true;
    });

    treeToClose.opened = false;
    treeToClose.icon = 'fa-folder';
    return treeToClose;
  },

  removeFromOpenedFiles(file) {
    if (file.type === 'tree') return;
    let foundIndex;
    RepoStore.openedFiles = RepoStore.openedFiles.filter((openedFile, i) => {
      if (openedFile.path === file.path) foundIndex = i;
      return openedFile.path !== file.path;
    });

    // now activate the right tab based on what you closed.
    if (RepoStore.openedFiles.length === 0) {
      RepoStore.activeFile = {};
      return;
    }

    if (RepoStore.openedFiles.length === 1 || foundIndex === 0) {
      RepoStore.setActiveFiles(RepoStore.openedFiles[0]);
      return;
    }

    if (foundIndex && foundIndex > 0) {
      RepoStore.setActiveFiles(RepoStore.openedFiles[foundIndex - 1]);
    }
  },

  addToOpenedFiles(file) {
    const openFile = file;

    const openedFilesAlreadyExists = RepoStore.openedFiles
      .some(openedFile => openedFile.path === openFile.path);

    if (openedFilesAlreadyExists) return;

    openFile.changed = false;
    RepoStore.openedFiles.push(openFile);
  },

  setActiveFileContents(contents) {
    if (!RepoStore.editMode) return;
    const currentFile = RepoStore.openedFiles[RepoStore.activeFileIndex];
    RepoStore.activeFile.newContent = contents;
    RepoStore.activeFile.changed = RepoStore.activeFile.plain !== RepoStore.activeFile.newContent;
    currentFile.changed = RepoStore.activeFile.changed;
    currentFile.newContent = contents;
  },

  toggleBlobView() {
    RepoStore.currentBlobView = RepoStore.isPreviewView() ? 'repo-editor' : 'repo-preview';
  },

  setViewToPreview() {
    RepoStore.currentBlobView = 'repo-preview';
  },

  // getters

  isActiveFile(file) {
    return file && file.url === RepoStore.activeFile.url;
  },

  isPreviewView() {
    return RepoStore.currentBlobView === 'repo-preview';
  },
};

export default RepoStore;
