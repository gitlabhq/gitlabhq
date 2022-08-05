import { editor as monacoEditor, Uri } from 'monaco-editor';
import { insertFinalNewline } from '~/lib/utils/text_utility';
import eventHub from '../../eventhub';
import { trimTrailingWhitespace } from '../../utils';
import { defaultModelOptions } from '../editor_options';
import Disposable from './disposable';

export default class Model {
  constructor(file, head = null) {
    this.disposable = new Disposable();
    this.file = file;
    this.head = head;
    this.content = file.content !== '' || file.deleted ? file.content : file.raw;
    this.options = { ...defaultModelOptions };

    this.disposable.add(
      (this.originalModel = monacoEditor.createModel(
        head ? head.content : this.file.raw,
        undefined,
        new Uri('gitlab', false, `original/${this.path}`),
      )),
      (this.model = monacoEditor.createModel(
        this.content,
        undefined,
        new Uri('gitlab', false, this.path),
      )),
    );
    if (this.file.mrChange) {
      this.disposable.add(
        (this.baseModel = monacoEditor.createModel(
          this.file.baseRaw,
          undefined,
          new Uri('gitlab', false, `target/${this.path}`),
        )),
      );
    }

    this.events = new Set();

    this.updateContent = this.updateContent.bind(this);
    this.updateNewContent = this.updateNewContent.bind(this);
    this.dispose = this.dispose.bind(this);

    eventHub.$on(`editor.update.model.dispose.${this.file.key}`, this.dispose);
    eventHub.$on(`editor.update.model.content.${this.file.key}`, this.updateContent);
    eventHub.$on(`editor.update.model.new.content.${this.file.key}`, this.updateNewContent);
  }

  get url() {
    return this.model.uri.toString();
  }

  get language() {
    return this.model.getLanguageId();
  }

  get path() {
    return this.file.key;
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
    this.events.add(this.disposable.add(this.model.onDidChangeContent((e) => cb(this, e))));
  }

  onDispose(cb) {
    this.events.add(cb);
  }

  updateContent({ content, changed }) {
    this.getOriginalModel().setValue(content);

    if (!changed) {
      this.getModel().setValue(content);
    }
  }

  updateNewContent(content) {
    this.getModel().setValue(content);
  }

  updateOptions(obj = {}) {
    Object.assign(this.options, obj);
    this.model.updateOptions(obj);
    this.applyCustomOptions();
  }

  applyCustomOptions() {
    this.updateNewContent(
      Object.entries(this.options).reduce((content, [key, value]) => {
        switch (key) {
          case 'endOfLine':
            this.model.pushEOL(value);
            return this.model.getValue();
          case 'insertFinalNewline':
            return value ? insertFinalNewline(content) : content;
          case 'trimTrailingWhitespace':
            return value ? trimTrailingWhitespace(content) : content;
          default:
            return content;
        }
      }, this.model.getValue()),
    );
  }

  dispose() {
    if (!this.model.isDisposed()) this.applyCustomOptions();

    this.events.forEach((cb) => {
      if (typeof cb === 'function') cb();
    });

    this.events.clear();

    eventHub.$off(`editor.update.model.dispose.${this.file.key}`, this.dispose);
    eventHub.$off(`editor.update.model.content.${this.file.key}`, this.updateContent);
    eventHub.$off(`editor.update.model.new.content.${this.file.key}`, this.updateNewContent);

    this.disposable.dispose();
  }
}
