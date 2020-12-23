export default class DeployKeysStore {
  constructor() {
    this.keys = {};
  }

  isEnabled(id) {
    return this.keys.enabled_keys.some((key) => key.id === id);
  }
}
