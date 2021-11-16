import { EDITOR_EXTENSION_DEFINITION_ERROR } from './constants';

export default class EditorExtension {
  constructor({ definition, setupOptions } = {}) {
    if (typeof definition !== 'function') {
      throw new Error(EDITOR_EXTENSION_DEFINITION_ERROR);
    }
    this.name = definition.name; // both class- and fn-based extensions have a name
    this.setupOptions = setupOptions;
    // eslint-disable-next-line new-cap
    this.obj = new definition();
  }

  get api() {
    return this.obj.provides?.();
  }
}
