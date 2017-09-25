/* global Flash */
import Vue from 'vue';
import Service from '../services/repo_service';
import Store from '../stores/repo_store';
import '../../flash';

const RepoHelper = {
  monacoInstance: null,

  getDefaultActiveFile() {
    return {
      active: true,
      binary: false,
      extension: '',
      html: '',
      mime_type: '',
      name: '',
      lastCommitMessage: '',
      lastCommitUrl: '',
      plain: '',
      size: 0,
      url: '',
      raw: false,
      newContent: '',
      changed: false,
      loading: false,
    };
  },

  key: '',

  isTree(data) {
    return Object.hasOwnProperty.call(data, 'blobs');
  },

  Time: window.performance
  && window.performance.now
  ? window.performance
  : Date,

  getFileExtension(fileName) {
    return fileName.split('.').pop();
  },

  getLanguageIDForFile(file, langs) {
    const ext = RepoHelper.getFileExtension(file.name);
    const foundLang = RepoHelper.findLanguage(ext, langs);

    return foundLang ? foundLang.id : 'plaintext';
  },

  setMonacoModelFromLanguage() {
    RepoHelper.monacoInstance.setModel(null);
    const languages = RepoHelper.monaco.languages.getLanguages();
    const languageID = RepoHelper.getLanguageIDForFile(Store.activeFile, languages);
    const newModel = RepoHelper.monaco.editor.createModel(Store.blobRaw, languageID);
    RepoHelper.monacoInstance.setModel(newModel);
  },

  findLanguage(ext, langs) {
    return langs.find(lang => lang.extensions && lang.extensions.indexOf(`.${ext}`) > -1);
  },

  setDirectoryOpen(tree) {
    const file = tree;
    if (!file) return undefined;

    file.opened = true;
    file.icon = 'fa-folder-open';
    RepoHelper.updateHistoryEntry(file.url, file.name);
    return file;
  },

  isRenderable() {
    const okExts = ['md', 'svg'];
    return okExts.indexOf(Store.activeFile.extension) > -1;
  },

  setBinaryDataAsBase64(file) {
    Service.getBase64Content(file.raw_path)
    .then((response) => {
      Store.blobRaw = response;
      file.base64 = response; // eslint-disable-line no-param-reassign
    })
    .catch(RepoHelper.loadingError);
  },

  // when you open a directory you need to put the directory files under
  // the directory... This will merge the list of the current directory and the new list.
  getNewMergedList(inDirectory, currentList, newList) {
    const newListSorted = newList.sort(this.compareFilesCaseInsensitive);
    if (!inDirectory) return newListSorted;
    const indexOfFile = currentList.findIndex(file => file.url === inDirectory.url);
    if (!indexOfFile) return newListSorted;
    return RepoHelper.mergeNewListToOldList(newListSorted, currentList, inDirectory, indexOfFile);
  },

  // within the get new merged list this does the merging of the current list of files
  // and the new list of files. The files are never "in" another directory they just
  // appear like they are because of the margin.
  mergeNewListToOldList(newList, oldList, inDirectory, indexOfFile) {
    newList.reverse().forEach((newFile) => {
      const fileIndex = indexOfFile + 1;
      const file = newFile;
      file.level = inDirectory.level + 1;
      oldList.splice(fileIndex, 0, file);
    });

    return oldList;
  },

  compareFilesCaseInsensitive(a, b) {
    const aName = a.name.toLowerCase();
    const bName = b.name.toLowerCase();
    if (a.level > 0) return 0;
    if (aName < bName) { return -1; }
    if (aName > bName) { return 1; }
    return 0;
  },

  isRoot(url) {
    // the url we are requesting -> split by the project URL. Grab the right side.
    const isRoot = !!url.split(Store.projectUrl)[1]
    // remove the first "/"
    .slice(1)
    // split this by "/"
    .split('/')
    // remove the first two items of the array... usually /tree/master.
    .slice(2)
    // we want to know the length of the array.
    // If greater than 0 not root.
    .length;
    return isRoot;
  },

  getRecentCommits(url) {
    // don't grab recent commits if we can't show them.
    if(Store.openedFiles.length) return;
    Service.getRecentCommits(url)
    .then(data => {
      const lastCommitFilesData = data.data;
      Store.files.map((currentFile, i) => {
        const [lastCommitFile] = lastCommitFilesData
          .filter((lastCommitFile) => {
            return lastCommitFile.path === currentFile.path;
        });

        if (lastCommitFile && lastCommitFile.commit) {
          currentFile.lastCommitUrl = '';
          currentFile.lastCommitMessage = lastCommitFile.commit.message;
          currentFile.lastCommitUpdate = lastCommitFile.commit.committed_date;
          return currentFile;  
        } else {
          currentFile.lastCommitMessage = '';
          currentFile.lastCommitUpdate = '';
          currentFile.lastCommitUrl = '';
          return currentFile;
        }
      });
      console.log('Store.files',Store.files);
    });
  },

  getContent(treeOrFile) {
    let file = treeOrFile;
    return Service.getContent()
    .then((response) => {
      const data = response.data;
      Store.isTree = RepoHelper.isTree(data);
      if (!Store.isTree) {
        if (!file) file = data;
        Store.binary = data.binary;

        if (data.binary) {
          // file might be undefined
          RepoHelper.setBinaryDataAsBase64(data);
          Store.setViewToPreview();
        } else if (!Store.isPreviewView()) {
          if (!data.render_error) {
            Service.getRaw(data.raw_path)
            .then((rawResponse) => {
              Store.blobRaw = rawResponse.data;
              data.plain = rawResponse.data;
              RepoHelper.setFile(data, file);
            }).catch(RepoHelper.loadingError);
          }
        }

        if (Store.isPreviewView()) {
          RepoHelper.setFile(data, file);
        }

        // if the file tree is empty
        if (Store.files.length === 0) {
          const parentURL = Service.blobURLtoParentTree(Service.url);
          Service.url = parentURL;
          RepoHelper.getContent();
        }
      } else {
        // it's a tree
        RepoHelper.getRecentCommits(data.last_commit_path);
        if (!file) Store.isRoot = RepoHelper.isRoot(Service.url);
        file = RepoHelper.setDirectoryOpen(file);
        const newDirectory = RepoHelper.dataToListOfFiles(data);
        Store.addFilesToDirectory(file, Store.files, newDirectory);
        Store.prevURL = Service.blobURLtoParentTree(Service.url);
      }
    }).catch(RepoHelper.loadingError);
  },

  setFile(data, file) {
    const newFile = data;

    newFile.url = file.url;
    if (newFile.render_error === 'too_large' || newFile.render_error === 'collapsed') {
      newFile.tooLarge = true;
    }
    newFile.newContent = '';

    Store.addToOpenedFiles(newFile);
    Store.setActiveFiles(newFile);
  },

  serializeBlob(blob) {
    const simpleBlob = RepoHelper.serializeRepoEntity('blob', blob);
    simpleBlob.loading = false;
    return simpleBlob;
  },

  serializeTree(tree) {
    return RepoHelper.serializeRepoEntity('tree', tree);
  },

  serializeSubmodule(submodule) {
    return RepoHelper.serializeRepoEntity('submodule', submodule);
  },

  serializeRepoEntity(type, entity) {
    const { url, name, icon, last_commit, path } = entity;
    const returnObj = {
      type,
      name,
      url,
      path,
      icon: `fa-${icon}`,
      level: 0,
      loading: false,
    };

    if (entity.last_commit) {
      returnObj.lastCommitUrl = `${Store.projectUrl}/commit/${last_commit.id}`;
    } else {
      returnObj.lastCommitUrl = '';
    }
    return returnObj;
  },

  scrollTabsRight() {
    // wait for the transition. 0.1 seconds.
    setTimeout(() => {
      const tabs = document.getElementById('tabs');
      if (!tabs) return;
      tabs.scrollLeft = tabs.scrollWidth;
    }, 200);
  },

  dataToListOfFiles(data) {
    const { blobs, trees, submodules } = data;
    return [
      ...blobs.map(blob => RepoHelper.serializeBlob(blob)),
      ...trees.map(tree => RepoHelper.serializeTree(tree)),
      ...submodules.map(submodule => RepoHelper.serializeSubmodule(submodule)),
    ];
  },

  genKey() {
    return RepoHelper.Time.now().toFixed(3);
  },

  updateHistoryEntry(url, title) {
    const history = window.history;

    RepoHelper.key = RepoHelper.genKey();

    history.pushState({ key: RepoHelper.key }, '', url);

    if (title) {
      document.title = `${title} · GitLab`;
    }
  },

  findOpenedFileFromActive() {
    return Store.openedFiles.find(openedFile => Store.activeFile.url === openedFile.url);
  },

  loadingError(e) {
    console.log(e)
    Flash('Unable to load this content at this time.');
  },
};

export default RepoHelper;
