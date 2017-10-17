import { convertPermissionToBoolean } from '../../lib/utils/common_utils';
import Service from '../services/repo_service';
import Store from '../stores/repo_store';
import Flash from '../../flash';

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

  setDirectoryOpen(tree, title) {
    if (!tree) return;

    Object.assign(tree, {
      opened: true,
    });

    RepoHelper.updateHistoryEntry(tree.url, title);
  },

  setDirectoryToClosed(entry) {
    Object.assign(entry, {
      opened: false,
      files: [],
    });
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

  getContent(treeOrFile, emptyFiles = false) {
    let file = treeOrFile;

    if (!Store.files.length) {
      Store.loading.tree = true;
    }

    return Service.getContent()
    .then((response) => {
      const data = response.data;
      if (response.headers && response.headers['page-title']) data.pageTitle = response.headers['page-title'];
      if (response.headers && response.headers['is-root'] && !Store.isInitialRoot) {
        Store.isRoot = convertPermissionToBoolean(response.headers['is-root']);
        Store.isInitialRoot = Store.isRoot;
      }

      if (file && file.type === 'blob') {
        if (!file) file = data;
        Store.binary = data.binary;

        if (data.binary) {
          // file might be undefined
          RepoHelper.setBinaryDataAsBase64(data);
          Store.setViewToPreview();
        } else if (!Store.isPreviewView() && !data.render_error) {
          Service.getRaw(data.raw_path)
          .then((rawResponse) => {
            Store.blobRaw = rawResponse.data;
            data.plain = rawResponse.data;
            RepoHelper.setFile(data, file);
          }).catch(RepoHelper.loadingError);
        }

        if (Store.isPreviewView()) {
          RepoHelper.setFile(data, file);
        }
      } else {
        Store.loading.tree = false;
        RepoHelper.setDirectoryOpen(file, data.pageTitle || data.name);

        if (emptyFiles) {
          Store.files = [];
        }

        this.addToDirectory(file, data);

        Store.prevURL = Service.blobURLtoParentTree(Service.url);
      }
    }).catch(RepoHelper.loadingError);
  },

  addToDirectory(file, data) {
    const tree = file || Store;
    const files = tree.files.concat(this.dataToListOfFiles(data, file ? file.level + 1 : 0));

    tree.files = files;
  },

  setFile(data, file) {
    const newFile = data;
    newFile.url = file.url || Service.url; // Grab the URL from service, happens on page refresh.

    if (newFile.render_error === 'too_large' || newFile.render_error === 'collapsed') {
      newFile.tooLarge = true;
    }
    newFile.newContent = '';

    Store.addToOpenedFiles(newFile);
    Store.setActiveFiles(newFile);
  },

  serializeRepoEntity(type, entity, level = 0) {
    const { url, name, icon, last_commit } = entity;

    return {
      type,
      name,
      url,
      level,
      icon: `fa-${icon}`,
      files: [],
      loading: false,
      opened: false,
      // eslint-disable-next-line camelcase
      lastCommit: last_commit ? {
        url: `${Store.projectUrl}/commit/${last_commit.id}`,
        message: last_commit.message,
        updatedAt: last_commit.committed_date,
      } : {},
    };
  },

  scrollTabsRight() {
    const tabs = document.getElementById('tabs');
    if (!tabs) return;
    tabs.scrollLeft = tabs.scrollWidth;
  },

  dataToListOfFiles(data, level) {
    const { blobs, trees, submodules } = data;
    return [
      ...trees.map(tree => RepoHelper.serializeRepoEntity('tree', tree, level)),
      ...submodules.map(submodule => RepoHelper.serializeRepoEntity('submodule', submodule, level)),
      ...blobs.map(blob => RepoHelper.serializeRepoEntity('blob', blob, level)),
    ];
  },

  genKey() {
    return RepoHelper.Time.now().toFixed(3);
  },

  updateHistoryEntry(url, title) {
    const history = window.history;

    RepoHelper.key = RepoHelper.genKey();

    if (document.location.pathname !== url) {
      history.pushState({ key: RepoHelper.key }, '', url);
    }

    if (title) {
      document.title = title;
    }
  },

  findOpenedFileFromActive() {
    return Store.openedFiles.find(openedFile => Store.activeFile.url === openedFile.url);
  },

  getFileFromPath(path) {
    return Store.openedFiles.find(file => file.url === path);
  },

  loadingError() {
    Flash('Unable to load this content at this time.');
  },
};

export default RepoHelper;
