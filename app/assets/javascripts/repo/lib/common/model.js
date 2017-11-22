/* global monaco */
import Disposable from './disposable';

export default class Model {
  constructor(monaco, file) {
    this.monaco = monaco;
    this.disposable = new Disposable();
    this.file = file;
    this.content = file.content !== '' ? file.content : file.raw;

    this.disposable.add(
      this.originalModel = this.monaco.editor.createModel(
        this.file.raw,
        undefined,
        new this.monaco.Uri(null, null, `original/${this.file.path}`),
      ),
      this.model = this.monaco.editor.createModel(
        this.content,
        undefined,
        new this.monaco.Uri(null, null, this.file.path),
      ),
    );

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
    return Model.getDiffModel(this.model);
  }

  get originalDiffModel() {
    return Model.getDiffModel(this.originalModel);
  }

  static getDiffModel(model) {
    return {
      url: model.uri.toString(),
      versionId: model.getVersionId(),
      lines: model.getLinesContent(),
      EOL: '\n',
    };
  }

  getModel() {
    return this.model;
  }

  getOriginalModel() {
    return this.originalModel;
  }

  onChange(cb) {
    this.events.set(
      this.file.path,
      this.disposable.add(
        this.model.onDidChangeContent(e => cb(this.model, e)),
      ),
    );
  }

  dispose() {
    this.disposable.dispose();
    this.events.clear();
  }
}
