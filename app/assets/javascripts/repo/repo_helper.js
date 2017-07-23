/* global Flash */
import Service from './repo_service';
import Store from './repo_store';
import '../flash';

const RepoHelper = {
  key: '',

  isTree(data) {
    return Object.hasOwnProperty.call(data, 'blobs');
  },

  Time: window.performance
  && window.performance.now
  ? window.performance
  : Date,

  getLanguageIDForFile(file, langs) {
    const ext = file.name.split('.').pop();
    const foundLang = RepoHelper.findLanguage(ext, langs);

    return foundLang ? foundLang.id : 'plaintext';
  },

  findLanguage(ext, langs) {
    return langs.find(lang => lang.extensions && lang.extensions.indexOf(`.${ext}`) > -1);
  },

  setDirectoryOpen(tree) {
    let file = tree;
    if (!file) return;

    file.opened = true;
    file.icon = 'fa-folder-open';
    return file;
  },

  getRawURLFromBlobURL(url) {
    return url.replace('blob', 'raw');
  },

  getBlameURLFromBlobURL(url) {
    return url.replace('blob', 'blame');
  },

  getHistoryURLFromBlobURL(url) {
    return url.replace('blob', 'commits');
  },

  setBinaryDataAsBase64(url, file) {
    Service.getBase64Content(url)
    .then((response) => {
      Store.blobRaw = response;
      file.base64 = response; // eslint-disable-line no-param-reassign
    })
    .catch(RepoHelper.loadingError);
  },

  toggleFakeTab(loading, file) {
    if (loading) return Store.addPlaceholderFile();
    return Store.removeFromOpenedFiles(file);
  },

  setLoading(loading, file) {
    if (Service.url.indexOf('blob') > -1) {
      Store.loading.blob = loading;
      return RepoHelper.toggleFakeTab(loading, file);
    }

    if (Service.url.indexOf('tree') > -1) Store.loading.tree = loading;

    return undefined;
  },

  getNewMergedList(inDirectory, currentList, newList) {
    if (!inDirectory) return newList;

    const indexOfFile = currentList.findIndex(file => file.url === inDirectory.url);

    if (!indexOfFile) return newList;

    return RepoHelper.mergeNewListToOldList(newList, currentList, inDirectory, indexOfFile);
  },

  mergeNewListToOldList(newList, oldList, inDirectory, indexOfFile) {
    newList.forEach((newFile) => {
      const fileIndex = indexOfFile + 1;
      const file = newFile;
      file.level = inDirectory.level + 1;

      oldList.splice(fileIndex, 0, file);
    });

    return oldList;
  },

  getContent(treeOrFile, cb) {
    let file = treeOrFile;
    // const loadingData = RepoHelper.setLoading(true);
    Service.getContent()
    .then((response) => {
      const data = response.data;
      // RepoHelper.setLoading(false, loadingData);
      if(cb) cb();
      Store.isTree = RepoHelper.isTree(data);
      if (!Store.isTree) {
        if (!file) file = data;
        Store.binary = data.binary;

        if (data.binary) {
          Store.binaryMimeType = data.mime_type;
          const rawUrl = RepoHelper.getRawURLFromBlobURL(file.url);
          RepoHelper.setBinaryDataAsBase64(rawUrl, data);
          data.binary = true;
        } else {
          Store.blobRaw = data.plain;
          data.binary = false;
        }

        if (!file.url) file.url = location.pathname;

        data.url = file.url;
        data.newContent = '';

        Store.addToOpenedFiles(data);
        Store.setActiveFiles(data);

        // if the file tree is empty
        if (Store.files.length === 0) {
          const parentURL = Service.blobURLtoParentTree(Service.url);
          Service.url = parentURL;
          RepoHelper.getContent();
        }
      } else {
        // it's a tree
        file = RepoHelper.setDirectoryOpen(file);
        const newDirectory = RepoHelper.dataToListOfFiles(data);
        Store.addFilesToDirectory(file, Store.files, newDirectory);
        Store.prevURL = Service.blobURLtoParentTree(Service.url);
      }
    })
    .catch(() => {
      RepoHelper.setLoading(false, loadingData);
      RepoHelper.loadingError();
    });
  },

  toFA(icon) {
    return `fa-${icon}`;
  },

  serializeBlob(blob) {
    const simpleBlob = RepoHelper.serializeRepoEntity('blob', blob);
    simpleBlob.lastCommitMessage = blob.last_commit.message;
    simpleBlob.lastCommitUpdate = blob.last_commit.committed_date;
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
    const { url, name, icon } = entity;

    return {
      type,
      name,
      url,
      icon: RepoHelper.toFA(icon),
      level: 0,
      loading: false,
    };
  },

  dataToListOfFiles(data) {
    const a = [];

    // push in blobs
    data.blobs.forEach((blob) => {
      a.push(RepoHelper.serializeBlob(blob));
    });

    data.trees.forEach((tree) => {
      a.push(RepoHelper.serializeTree(tree));
    });

    data.submodules.forEach((submodule) => {
      a.push(RepoHelper.serializeSubmodule(submodule));
    });

    return a;
  },

  genKey() {
    return RepoHelper.Time.now().toFixed(3);
  },

  getStateKey() {
    return RepoHelper.key;
  },

  setStateKey(key) {
    RepoHelper.key = key;
  },

  toURL(url) {
    const history = window.history;

    RepoHelper.key = RepoHelper.genKey();

    history.pushState({ key: RepoHelper.key }, '', url);
  },

  loadingError() {
    Flash('Unable to load the file at this time.');
  },
};

export default RepoHelper;
