import Service from '../services/repo_service';
import Store from '../stores/repo_store';
import Flash from '../../flash';

const RepoHelper = {
  monacoInstance: null,

  getDefaultActiveFile() {
    return {
      id: '',
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
    Store.path = tree.path;
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
      if (response.headers && response.headers['page-title']) data.pageTitle = decodeURI(response.headers['page-title']);
      if (data.path && !Store.isInitialRoot) {
        Store.isRoot = data.path === '/';
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
          Service.getRaw(data)
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

    // TODO: Figure out why `popstate` is being trigger in the specs
    if (!tree.files) return;

    const files = tree.files.concat(this.dataToListOfFiles(data, file ? file.level + 1 : 0));

    tree.files = files;
  },

  setFile(data, file) {
    const newFile = data;
    newFile.url = file.url || Service.url; // Grab the URL from service, happens on page refresh.

    if (newFile.render_error === 'too_large' || newFile.render_error === 'collapsed') {
      newFile.tooLarge = true;
    }
    newFile.newContent = file.newContent ? file.newContent : '';

    Store.addToOpenedFiles(newFile);
    Store.setActiveFiles(newFile);
  },

  serializeRepoEntity(type, entity, level = 0) {
    const {
      id,
      url,
      name,
      icon,
      last_commit,
      tree_url,
      path,
      tempFile,
      active,
      opened,
    } = entity;

    return {
      id,
      type,
      name,
      url,
      tree_url,
      path,
      level,
      tempFile,
      icon: `fa-${icon}`,
      files: [],
      loading: false,
      opened,
      active,
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
    return Store.openedFiles.find(openedFile => Store.activeFile.id === openedFile.id);
  },

  getFileFromPath(path) {
    return Store.openedFiles.find(file => file.url === path);
  },

  loadingError() {
    Flash('Unable to load this content at this time.');
  },
  openEditMode() {
    Store.editMode = true;
    Store.currentBlobView = 'repo-editor';
  },
  updateStorePath(path) {
    Store.path = path;
  },
  findOrCreateEntry(type, tree, name) {
    let exists = true;
    let foundEntry = tree.files.find(dir => dir.type === type && dir.name === name);

    if (!foundEntry) {
      foundEntry = RepoHelper.serializeRepoEntity(type, {
        id: name,
        name,
        path: tree.path ? `${tree.path}/${name}` : name,
        icon: type === 'tree' ? 'folder' : 'file-text-o',
        tempFile: true,
        opened: true,
        active: true,
      }, tree.level !== undefined ? tree.level + 1 : 0);

      exists = false;
      tree.files.push(foundEntry);
    }

    return {
      entry: foundEntry,
      exists,
    };
  },
  removeAllTmpFiles(storeFilesKey) {
    Store[storeFilesKey] = Store[storeFilesKey].filter(f => !f.tempFile);
  },
  createNewEntry(options, openEditMode = true) {
    const {
      name,
      type,
      content = '',
      base64 = false,
    } = options;
    const originalPath = Store.path;
    let entryName = name;

    if (entryName.indexOf(`${originalPath}/`) !== 0) {
      this.updateStorePath('');
    } else {
      entryName = entryName.replace(`${originalPath}/`, '');
    }

    if (entryName === '') return;

    const fileName = type === 'tree' ? '.gitkeep' : entryName;
    let tree = Store;

    if (type === 'tree') {
      const dirNames = entryName.split('/');

      dirNames.forEach((dirName) => {
        if (dirName === '') return;

        tree = this.findOrCreateEntry('tree', tree, dirName).entry;
      });
    }

    if ((type === 'tree' && tree.tempFile) || type === 'blob') {
      const file = this.findOrCreateEntry('blob', tree, fileName);

      if (file.exists) {
        Flash(`The name "${file.entry.name}" is already taken in this directory.`);
      } else {
        const { entry } = file;
        entry.newContent = content;
        entry.base64 = base64;

        if (entry.base64) {
          entry.render_error = true;
        }

        this.setFile(entry, entry);

        if (openEditMode) {
          this.openEditMode();
        } else {
          file.entry.render_error = 'asdsad';
        }
      }
    }

    this.updateStorePath(originalPath);
  },
};

export default RepoHelper;
