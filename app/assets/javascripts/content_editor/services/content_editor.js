import { LOADING_CONTENT_EVENT, LOADING_SUCCESS_EVENT, LOADING_ERROR_EVENT } from '../constants';

/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer, deserializer, assetResolver, eventHub }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._deserializer = deserializer;
    this._eventHub = eventHub;
    this._assetResolver = assetResolver;
    this._pristineDoc = null;
  }

  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get eventHub() {
    return this._eventHub;
  }

  get changed() {
    return this._pristineDoc?.eq(this.tiptapEditor.state.doc);
  }

  get empty() {
    const doc = this.tiptapEditor?.state.doc;

    // Makes sure the document has more than one empty paragraph
    return doc.childCount === 0 || (doc.childCount === 1 && doc.child(0).childCount === 0);
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

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor, _eventHub: eventHub } = this;
    const { doc, tr } = editor.state;

    try {
      eventHub.$emit(LOADING_CONTENT_EVENT);
      const { document } = await this.deserialize(serializedContent);

      if (document) {
        this._pristineDoc = document;
        tr.replaceWith(0, doc.content.size, document).setMeta('preventUpdate', true);
        editor.view.dispatch(tr);
      }

      eventHub.$emit(LOADING_SUCCESS_EVENT);
    } catch (e) {
      eventHub.$emit(LOADING_ERROR_EVENT, e);
      throw e;
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer, _pristineDoc: pristineDoc } = this;
    const { doc } = editor.state;

    return serializer.serialize({ doc, pristineDoc });
  }
}
