/* global Flash */
import Service from '../services/repo_service';
import Store from '../stores/repo_store';
import '../../flash';

const RepoHelper = {
  getDefaultActiveFile() {
    return {
      active: true,
      binary: false,
      extension: '',
      html: '',
      mime_type: '',
      name: '',
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

  getBranch() {
    return $('button.dropdown-menu-toggle').attr('data-ref');
  },

  getLanguageIDForFile(file, langs) {
    const ext = RepoHelper.getFileExtension(file.name);
    const foundLang = RepoHelper.findLanguage(ext, langs);

    return foundLang ? foundLang.id : 'plaintext';
  },

  getFilePathFromFullPath(fullPath, branch) {
    return fullPath.split(`${Store.projectUrl}/blob/${branch}`)[1];
  },

  findLanguage(ext, langs) {
    return langs.find(lang => lang.extensions && lang.extensions.indexOf(`.${ext}`) > -1);
  },

  setDirectoryOpen(tree) {
    const file = tree;
    if (!file) return undefined;

    file.opened = true;
    file.icon = 'fa-folder-open';
    RepoHelper.toURL(file.url, file.name);
    return file;
  },

  isKindaBinary() {
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
    const newListSorted = newList.sort(this.compareFilesCaseInsensitive);
    if (!inDirectory) return newListSorted;
    const indexOfFile = currentList.findIndex(file => file.url === inDirectory.url);
    if (!indexOfFile) return newListSorted;
    return RepoHelper.mergeNewListToOldList(newListSorted, currentList, inDirectory, indexOfFile);
  },

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

  getContent(treeOrFile) {
    let file = treeOrFile;
    // const loadingData = RepoHelper.setLoading(true);
    return Service.getContent()
    .then((response) => {
      const data = response.data;
      // RepoHelper.setLoading(false, loadingData);
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
    const { url, name, icon, last_commit } = entity;
    const returnObj = {
      type,
      name,
      url,
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

  toURL(url, title) {
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

  loadingError() {
    Flash('Unable to load the file at this time.');
  },
};

export default RepoHelper;
