/* global monaco */
import Disposable from './disposable';

export default class Model {
  constructor(file) {
    this.disposable = new Disposable();
    this.file = file;
    this.content = file.content !== '' ? file.content : file.raw;

    this.disposable.add(
      this.originalModel = monaco.editor.createModel(
        this.content,
        undefined,
        new monaco.Uri(null, null, `original/${this.file.path}`),
      ),
      this.model = monaco.editor.createModel(
        this.content,
        undefined,
        new monaco.Uri(null, null, this.file.path),
      ),
    );

    this.attachedToWorker = false;
    this.events = new Map();
  }

  get url() {
    return this.model.uri.toString();
  }

  get originalUrl() {
    return this.originalModel.uri.toString();
  }

  get path() {
    return this.file.path;
  }

  get diffModel() {
    return {
      url: this.model.uri.toString(),
      versionId: this.model.getVersionId(),
      lines: this.model.getLinesContent(),
      EOL: '\n',
    };
  }

  get originalDiffModel() {
    return {
      url: this.originalModel.uri.toString(),
      versionId: this.originalModel.getVersionId(),
      lines: this.originalModel.getLinesContent(),
      EOL: '\n',
    };
  }

  getModel() {
    return this.model;
  }

  getOriginalModel() {
    return this.originalModel;
  }

  setAttachedToWorker(val) {
    this.attachedToWorker = val;
  }

  onChange(cb) {
    this.events.set(
      this.file.path,
      this.model.onDidChangeContent(e => cb(this.model, e)),
    );
  }

  dispose() {
    this.disposable.dispose();

    this.events.forEach(disposer => disposer.dispose());
    this.events.clear();
  }
}
