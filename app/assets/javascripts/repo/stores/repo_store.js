/* global Flash */
import RepoHelper from '../helpers/repo_helper';
import RepoService from '../services/repo_service';

const RepoStore = {
  ideEl: {},
  monaco: {},
  monacoInstance: {},
  service: '',
  editor: '',
  sidebar: '',
  editMode: false,
  isTree: false,
  isRoot: false,
  prevURL: '',
  projectId: '',
  projectName: '',
  projectUrl: '',
  trees: [],
  blobs: [],
  submodules: [],
  blobRaw: '',
  blobRendered: '',
  currentBlobView: 'repo-preview',
  openedFiles: [],
  tabSize: 100,
  defaultTabSize: 100,
  minTabSize: 30,
  tabsOverflow: 41,
  submitCommitsLoading: false,
  binaryLoaded: false,
  dialog: {
    open: false,
    title: '',
    status: false,
  },
  activeFile: RepoHelper.getDefaultActiveFile(),
  activeFileIndex: 0,
  activeLine: 0,
  activeFileLabel: 'Raw',
  files: [],
  isCommitable: false,
  binary: false,
  currentBranch: '',
  targetBranch: 'new-branch',
  commitMessage: '',
  binaryMimeType: '',
  // scroll bar space for windows
  scrollWidth: 0,
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
  readOnly: true,

  resetBinaryTypes() {
    Object.keys(RepoStore.binaryTypes).forEach((key) => {
      RepoStore.binaryTypes[key] = false;
    });
  },

  // mutations
  checkIsCommitable() {
    RepoStore.service.checkCurrentBranchIsCommitable()
      .then((data) => {
        // you shouldn't be able to make commits on commits or tags.
        const { Branches, Commits, Tags } = data.data;
        if (Branches && Branches.length) RepoStore.isCommitable = true;
        if (Commits && Commits.length) RepoStore.isCommitable = false;
        if (Tags && Tags.length) RepoStore.isCommitable = false;
      }).catch(() => Flash('Failed to check if branch can be committed to.'));
  },

  addFilesToDirectory(inDirectory, currentList, newList) {
    RepoStore.files = RepoHelper.getNewMergedList(inDirectory, currentList, newList);
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
      RepoStore.binaryMimeType = file.mime_type;
    } else if (file.newContent || file.plain) {
      RepoStore.blobRaw = file.newContent || file.plain;
    } else {
      RepoService.getRaw(file.raw_path)
        .then((rawResponse) => {
          RepoStore.blobRaw = rawResponse.data;
          RepoHelper.findOpenedFileFromActive().plain = rawResponse.data;
        }).catch(RepoHelper.loadingError);
    }

    if (!file.loading) RepoHelper.toURL(file.url, file.name);
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
    let wereDone = false;
    RepoStore.files = RepoStore.files.filter((file) => {
      const isItTheTreeWeWant = file.url === treeToClose.url;
      // if it's the next tree
      if (foundTree && file.type === 'tree' && !isItTheTreeWeWant && file.level === treeToClose.level) {
        wereDone = true;
        return true;
      }
      if (wereDone) return true;

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
      if (openedFile.url === file.url) foundIndex = i;
      return openedFile.url !== file.url;
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

    if (foundIndex) {
      if (foundIndex > 0) {
        RepoStore.setActiveFiles(RepoStore.openedFiles[foundIndex - 1]);
      }
    }
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
      fake: true,
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
