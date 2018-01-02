export default class Cache {
  constructor() {
    this.internalStorage = { };
  }

  get(key) {
    return this.internalStorage[key];
  }

  hasData(key) {
    return Object.prototype.hasOwnProperty.call(this.internalStorage, key);
  }

  remove(key) {
    delete this.internalStorage[key];
  }
}
