export default class DeployKeysStore {
  constructor() {
    this.keys = {};
  }

  findEnabledKey(id) {
    return this.keys.enabled_keys.find(key => key.id === id);
  }
}
