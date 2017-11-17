/* global monaco */

export default class Model {
  constructor(file) {
    this.file = file;
    this.content = file.content !== '' ? file.content : file.raw;
    this.originalModel = monaco.editor.createModel(
      this.content,
      undefined,
      new monaco.Uri(null, null, `original/${this.file.path}`),
    );
    this.model = monaco.editor.createModel(
      this.content,
      undefined,
      new monaco.Uri(null, null, this.file.path),
    );
    this.disposers = new Map();
  }

  get url() {
    return this.model.uri.toString();
  }

  getModel() {
    return this.model;
  }

  getOriginalModel() {
    return this.originalModel;
  }

  onChange(cb) {
    this.disposers.set(
      this.file.path,
      this.model.onDidChangeContent(e => cb(this.model, e)),
    );
  }

  dispose() {
    this.model.dispose();
    this.originalModel.dispose();

    this.disposers.forEach(disposer => disposer.dispose());
    this.disposers.clear();
  }
}
