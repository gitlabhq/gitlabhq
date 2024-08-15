import { DocAttrStep } from '@tiptap/pm/transform';

/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({
    tiptapEditor,
    serializer,
    deserializer,
    assetResolver,
    eventHub,
    drawioEnabled,
    codeSuggestionsConfig,
    autocompleteHelper,
  }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._deserializer = deserializer;
    this._eventHub = eventHub;
    this._assetResolver = assetResolver;
    this._pristineDoc = null;
    this._autocompleteHelper = autocompleteHelper;

    this.codeSuggestionsConfig = codeSuggestionsConfig;
    this.drawioEnabled = drawioEnabled;
  }

  /**
   * @type {import('@tiptap/core').Editor}
   */
  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get eventHub() {
    return this._eventHub;
  }

  get serializer() {
    return this._serializer;
  }

  get changed() {
    if (!this._pristineDoc) {
      return !this.empty;
    }

    return !this._pristineDoc.eq(this.tiptapEditor.state.doc);
  }

  get empty() {
    return this.tiptapEditor.isEmpty;
  }

  get editable() {
    return this.tiptapEditor.isEditable;
  }

  dispose() {
    this.tiptapEditor.destroy();
  }

  disposeAllEvents() {
    this._eventHub.dispose();
  }

  deserialize(markdown) {
    const { _tiptapEditor: editor, _deserializer: deserializer } = this;

    return deserializer.deserialize({
      schema: editor.schema,
      markdown,
    });
  }

  resolveUrl(canonicalSrc) {
    return this._assetResolver.resolveUrl(canonicalSrc);
  }

  resolveReference(originalText) {
    return this._assetResolver.resolveReference(originalText);
  }

  renderDiagram(code, language) {
    return this._assetResolver.renderDiagram(code, language);
  }

  explainQuickAction(text) {
    return this._assetResolver.explainQuickAction(text);
  }

  setEditable(editable = true) {
    this._tiptapEditor.setOptions({
      editable,
    });
  }

  updateAutocompleteDataSources(dataSources) {
    this._autocompleteHelper.updateDataSources(dataSources);
  }

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor } = this;

    const { document } = await this.deserialize(serializedContent);
    const { doc } = editor.state;

    if (document) {
      this._pristineDoc = document;
      let tr = editor.state.tr.replaceWith(0, doc.content.size, document);
      for (const [key, value] of Object.entries(document.attrs)) {
        tr = tr.step(new DocAttrStep(key, value));
      }
      editor.view.dispatch(tr.setMeta('preventUpdate', true));
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer, _pristineDoc: pristineDoc } = this;
    const { doc } = editor.state;

    return serializer.serialize({ doc, pristineDoc });
  }
}
