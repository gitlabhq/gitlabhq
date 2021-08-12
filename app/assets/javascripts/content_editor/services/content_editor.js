import eventHubFactory from '~/helpers/event_hub_factory';
import { LOADING_CONTENT_EVENT, LOADING_SUCCESS_EVENT, LOADING_ERROR_EVENT } from '../constants';
/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._eventHub = eventHubFactory();
  }

  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get empty() {
    const doc = this.tiptapEditor?.state.doc;

    // Makes sure the document has more than one empty paragraph
    return doc.childCount === 0 || (doc.childCount === 1 && doc.child(0).childCount === 0);
  }

  dispose() {
    this.tiptapEditor.destroy();
  }

  once(type, handler) {
    this._eventHub.$once(type, handler);
  }

  on(type, handler) {
    this._eventHub.$on(type, handler);
  }

  emit(type, params = {}) {
    this._eventHub.$emit(type, params);
  }

  off(type, handler) {
    this._eventHub.$off(type, handler);
  }

  disposeAllEvents() {
    this._eventHub.dispose();
  }

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor, _serializer: serializer } = this;

    try {
      this._eventHub.$emit(LOADING_CONTENT_EVENT);
      const document = await serializer.deserialize({
        schema: editor.schema,
        content: serializedContent,
      });
      editor.commands.setContent(document);
      this._eventHub.$emit(LOADING_SUCCESS_EVENT);
    } catch (e) {
      this._eventHub.$emit(LOADING_ERROR_EVENT, e);
      throw e;
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer } = this;

    return serializer.serialize({ schema: editor.schema, content: editor.getJSON() });
  }
}
