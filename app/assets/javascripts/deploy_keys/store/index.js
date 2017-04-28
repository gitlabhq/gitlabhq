export default class DeployKeysStore {
  constructor() {
    this.keys = {};
  }

  findEnabledKey(id) {
    return this.keys.enabled_keys.find(key => key.id === id);
  }

  removeKeyForType(deployKey, type) {
    this.keys[type] = this.keys[type].filter(key => key.id !== deployKey.id);
  }
}
