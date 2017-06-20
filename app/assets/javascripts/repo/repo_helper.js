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

  blobURLtoParent(url) {
    const split = url.split('/');
    split.pop();
    const blobIndex = split.indexOf('blob');
    if(blobIndex > -1) {
      split[blobIndex] = 'tree';
    }
    return split.join('/');
  },

    // may be tree or file.
  getContent() {
    Service.getContent()
    .then((response)=> {
      let data = response.data;
      Store.isTree = this.isTree(data);
      if(!Store.isTree) {
        // it's a blob
        const parentURL = this.blobURLtoParent(Service.url);
        Store.blobRaw = data.plain;
        Service.getContent(parentURL)
        .then((response)=> {
          console.log(response.data)
        })
        .catch((response)=> {

        });
      } else {
        // it's a tree
        Store.files = this.dataToListOfFiles(data);
      }
    })
    .catch((response)=> {
      console.log('error response', response);
    });
  },

  toFA(icon) {
    return `fa-${icon}`
  },

  dataToListOfFiles(data) {
    let a = [];

    //push in blobs
    data.blobs.forEach((blob) => {
      a.push({
        type: 'blob',
        name: blob.name,
        url: blob.url,
        icon: this.toFA(blob.icon)
      })
    });

    data.trees.forEach((tree) => {
      a.push({
        type: 'tree',
        name: tree.name,
        url: tree.url,
        icon: this.toFA(tree.icon)
      })
    });

    data.submodules.forEach((submodule) => {
      a.push({
        type: 'submodule',
        name: submodule.name,
        url: submodule.url,
        icon: this.toFA(submodule.icon)
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
    window.scrollTo(0, 0);
  }
};

export default RepoHelper;