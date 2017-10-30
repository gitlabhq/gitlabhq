import Helper from '../helpers/repo_helper';
import Service from '../services/repo_service';

const RepoStore = {
  monacoLoading: false,
  service: '',
  canCommit: false,
  onTopOfBranch: false,
  editMode: false,
  isRoot: null,
  isInitialRoot: null,
  prevURL: '',
  projectId: '',
  projectName: '',
  projectUrl: '',
  branchUrl: '',
  blobRaw: '',
  currentBlobView: 'repo-preview',
  openedFiles: [],
  submitCommitsLoading: false,
  dialog: {
    open: false,
    title: '',
    status: false,
  },
  showNewBranchDialog: false,
  activeFile: Helper.getDefaultActiveFile(),
  activeFileIndex: 0,
  activeLine: -1,
  activeFileLabel: 'Raw',
  files: [],
  isCommitable: false,
  binary: false,
  currentBranch: '',
  startNewMR: false,
  currentHash: '',
  currentShortHash: '',
  customBranchURL: '',
  newMrTemplateUrl: '',
  branchChanged: false,
  commitMessage: '',
  path: '',
  loading: {
    tree: false,
    blob: false,
  },

  setBranchHash() {
    return Service.getBranch()
      .then((data) => {
        if (RepoStore.currentHash !== '' && data.commit.id !== RepoStore.currentHash) {
          RepoStore.branchChanged = true;
        }
        RepoStore.currentHash = data.commit.id;
        RepoStore.currentShortHash = data.commit.short_id;
      });
  },

  // mutations
  checkIsCommitable() {
    RepoStore.isCommitable = RepoStore.onTopOfBranch && RepoStore.canCommit;
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
      Service.getRaw(file)
        .then((rawResponse) => {
          RepoStore.blobRaw = rawResponse.data;
          Helper.findOpenedFileFromActive().plain = rawResponse.data;
        }).catch(Helper.loadingError);
    }

    if (!file.loading && !file.tempFile) {
      Helper.updateHistoryEntry(file.url, file.pageTitle || file.name);
    }
    RepoStore.binary = file.binary;
    RepoStore.setActiveLine(-1);
  },

  setFileActivity(file, openedFile, i) {
    const activeFile = openedFile;
    activeFile.active = file.id === activeFile.id;

    if (activeFile.active) RepoStore.setActiveFile(activeFile, i);

    return activeFile;
  },

  setActiveFile(activeFile, i) {
    RepoStore.activeFile = Object.assign({}, Helper.getDefaultActiveFile(), activeFile);
    RepoStore.activeFileIndex = i;
  },

  setActiveLine(activeLine) {
    if (!isNaN(activeLine)) RepoStore.activeLine = activeLine;
  },

  setActiveToRaw() {
    RepoStore.activeFile.raw = false;
    // can't get vue to listen to raw for some reason so RepoStore for now.
    RepoStore.activeFileLabel = 'Display source';
  },

  removeFromOpenedFiles(file) {
    if (file.type === 'tree') return;
    let foundIndex;
    RepoStore.openedFiles = RepoStore.openedFiles.filter((openedFile, i) => {
      if (openedFile.path === file.path) foundIndex = i;
      return openedFile.path !== file.path;
    });

    // remove the file from the sidebar if it is a tempFile
    if (file.tempFile) {
      RepoStore.files = RepoStore.files.filter(f => !(f.tempFile && f.path === file.path));
    }

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
    openFile.active = true;
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
    return file && file.id === RepoStore.activeFile.id;
  },

  isPreviewView() {
    return RepoStore.currentBlobView === 'repo-preview';
  },
};

export default RepoStore;
