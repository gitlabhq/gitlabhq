/* global monaco */
import Disposable from './disposable';
import eventHub from '../../eventhub';

export default class Model {
  constructor(monaco, file) {
    this.monaco = monaco;
    this.disposable = new Disposable();
    this.file = file;
    this.content = file.content !== '' ? file.content : file.raw;

    this.disposable.add(
      (this.originalModel = this.monaco.editor.createModel(
        this.file.raw,
        undefined,
        new this.monaco.Uri(null, null, `original/${this.file.path}`),
      )),
      (this.model = this.monaco.editor.createModel(
        this.content,
        undefined,
        new this.monaco.Uri(null, null, this.file.path),
      )),
    );

    if (this.file.mrChange) {
      this.disposable.add(
        (this.baseModel = this.monaco.editor.createModel(
          this.file.baseRaw,
          undefined,
          new this.monaco.Uri(null, null, `target/${this.file.path}`),
        )),
      );
    }

    this.events = new Map();

    this.updateContent = this.updateContent.bind(this);
    this.dispose = this.dispose.bind(this);

    eventHub.$on(`editor.update.model.dispose.${this.file.path}`, this.dispose);
    eventHub.$on(`editor.update.model.content.${this.file.path}`, this.updateContent);
  }

  get url() {
    return this.model.uri.toString();
  }

  get language() {
    return this.model.getModeId();
  }

  get eol() {
    return this.model.getEOL() === '\n' ? 'LF' : 'CRLF';
  }

  get path() {
    return this.file.path;
  }

  getModel() {
    return this.model;
  }

  getOriginalModel() {
    return this.originalModel;
  }

  getBaseModel() {
    return this.baseModel;
  }

  setValue(value) {
    this.getModel().setValue(value);
  }

  onChange(cb) {
    this.events.set(
      this.path,
      this.disposable.add(this.model.onDidChangeContent(e => cb(this, e))),
    );
  }

  updateContent(content) {
    this.getOriginalModel().setValue(content);
    this.getModel().setValue(content);
  }

  dispose() {
    this.disposable.dispose();
    this.events.clear();

    eventHub.$off(`editor.update.model.dispose.${this.file.path}`, this.dispose);
    eventHub.$off(`editor.update.model.content.${this.file.path}`, this.updateContent);
  }
}
