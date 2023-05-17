/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer, deserializer, assetResolver, eventHub, drawioEnabled }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._deserializer = deserializer;
    this._eventHub = eventHub;
    this._assetResolver = assetResolver;
    this._pristineDoc = null;

    this.drawioEnabled = drawioEnabled;
  }

  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get eventHub() {
    return this._eventHub;
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

  renderDiagram(code, language) {
    return this._assetResolver.renderDiagram(code, language);
  }

  setEditable(editable = true) {
    this._tiptapEditor.setOptions({
      editable,
    });
  }

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor } = this;
    const { doc, tr } = editor.state;

    const { document } = await this.deserialize(serializedContent);

    if (document) {
      this._pristineDoc = document;
      tr.replaceWith(0, doc.content.size, document).setMeta('preventUpdate', true);
      editor.view.dispatch(tr);
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer, _pristineDoc: pristineDoc } = this;
    const { doc } = editor.state;

    return serializer.serialize({ doc, pristineDoc });
  }
}
