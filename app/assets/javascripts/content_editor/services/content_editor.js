import { TextSelection } from 'prosemirror-state';
import { LOADING_CONTENT_EVENT, LOADING_SUCCESS_EVENT, LOADING_ERROR_EVENT } from '../constants';

/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer, deserializer, eventHub }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._deserializer = deserializer;
    this._eventHub = eventHub;
  }

  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get eventHub() {
    return this._eventHub;
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

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor, _deserializer: deserializer, _eventHub: eventHub } = this;
    const { doc, tr } = editor.state;
    const selection = TextSelection.create(doc, 0, doc.content.size);

    try {
      eventHub.$emit(LOADING_CONTENT_EVENT);
      const { document } = await deserializer.deserialize({
        schema: editor.schema,
        content: serializedContent,
      });

      if (document) {
        tr.setSelection(selection)
          .replaceSelectionWith(document, false)
          .setMeta('preventUpdate', true);
        editor.view.dispatch(tr);
      }
      eventHub.$emit(LOADING_SUCCESS_EVENT);
    } catch (e) {
      eventHub.$emit(LOADING_ERROR_EVENT, e);
      throw e;
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer } = this;

    return serializer.serialize({ schema: editor.schema, content: editor.getJSON() });
  }
}
