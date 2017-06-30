import Service from './repo_service'
import Store from './repo_store'

let RepoHelper = {
  isTree(data) {
    return data.hasOwnProperty('blobs');
  },

  Time: window.performance
  && window.performance.now
  ? window.performance
  : Date,

  getLanguagesForMimeType(mimetypeNeedle, monaco) {
    const langs = monaco.languages.getLanguages();
    let lang = '';
    langs.every((lang) => {
      const hasLang = lang.mimetypes.some((mimetype) => {
        return mimetypeNeedle === mimetype
      });
      if(hasLang) {
        lang = lang.id;
        return true;
      }
      return false;
    });
  },

  blobURLtoParent(url) {
    const split = url.split('/');
    split.pop();
    const blobIndex = split.indexOf('blob');
    if(blobIndex > -1) {
      split[blobIndex] = 'tree';
    }
    return split.join('/');
  },

  insertNewFilesIntoParentDir(inDirectory, oldList, newList) {
    let indexOfFile;
    if(!inDirectory) {
      return newList;
    }
    oldList.find((file, i) => {
      if(file.url === inDirectory.url){
        indexOfFile = i+1;
        return true;
      }
      return false;
    });
    if(indexOfFile){
      // insert new list into old list
      newList.forEach((newFile) => {
        newFile.level = inDirectory.level + 1;
        oldList.splice(indexOfFile, 0, newFile);
      });
      return oldList;
    }
    return newList;
  },

  setActiveFile(file) {
    Store.openedFiles = Store.openedFiles.map((openedFile) => {
      openedFile.active = file.url === openedFile.url;
      return openedFile;
    });
    Store.blobRaw = file.plain;
    this.toURL(file.url);
  },

  removeFromOpenedFiles(file) {
    if(file.type === 'tree') return;
    Store.openedFiles = Store.openedFiles.filter((openedFile) => {
      return openedFile.url !== file.url;
    });
  },

  addToOpenedFiles(file) {
    const openedFilesAlreadyExists = Store.openedFiles.some((openedFile) => {
      return openedFile.url === file.url
    });
    if(!openedFilesAlreadyExists) {
      Store.openedFiles.push(file);
    }
  },

  setDirectoryOpen(tree) {
    if(tree) {
      tree.opened = true;
      tree.icon = 'fa-folder-open';
    }
  },

    // may be tree or file.
  getContent(file) {
    Service.getContent()
    .then((response) => {
      let data = response.data;
      Store.isTree = this.isTree(data);
      if(!Store.isTree) {
        // it's a blob
        const parentURL = this.blobURLtoParent(Service.url);
        Store.blobRaw = data.plain;
        Store.prevURL = this.blobURLtoParent(parentURL);
        data.url = file.url;
        this.addToOpenedFiles(data);
        this.setActiveFile(data);
      } else {
        // it's a tree
        this.setDirectoryOpen(file);
        let newDirectory = this.dataToListOfFiles(data);
        Store.files = this.insertNewFilesIntoParentDir(file, Store.files, newDirectory);
        Store.prevURL = this.blobURLtoParent(Service.url);
      }
    })
    .catch((response)=> {
      console.log('error response', response);
    });
  },

  toFA(icon) {
    return `fa-${icon}`;
  },

  removeChildFilesOfTree(tree) {
    let foundTree = false;
    Store.files = Store.files.filter((file) => {
      if(file.url === tree.url) {
        foundTree = true;
      }
      if(foundTree) {
        return file.level <= tree.level
      } else {
        return true;
      }
    });

    tree.opened = false;
    tree.icon = 'fa-folder';

  },

  dataToListOfFiles(data) {
    let a = [];

    //push in blobs
    data.blobs.forEach((blob) => {
      a.push({
        type: 'blob',
        name: blob.name,
        url: blob.url,
        icon: this.toFA(blob.icon),
        lastCommitMessage: blob.last_commit.message,
        lastCommitUpdate: blob.last_commit.committed_date,
        level: 0
      })
    });

    data.trees.forEach((tree) => {
      a.push({
        type: 'tree',
        name: tree.name,
        url: tree.url,
        icon: this.toFA(tree.icon),
        level: 0
      })
    });

    data.submodules.forEach((submodule) => {
      a.push({
        type: 'submodule',
        name: submodule.name,
        url: submodule.url,
        icon: this.toFA(submodule.icon),
        level: 0
      })
    });

    return a;
  },

  genKey () {
    return this.Time.now().toFixed(3)
  },

  _key: '',

  getStateKey () {
    return this._key
  },

  setStateKey (key) {
    this._key = key;
  },

  toURL(url) {
    var history = window.history;
    this._key = this.genKey();
    history.pushState({ key: this._key }, '', url);
  }
};

export default RepoHelper;