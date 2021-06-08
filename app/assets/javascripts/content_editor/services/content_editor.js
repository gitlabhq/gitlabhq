/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
  }

  get tiptapEditor() {
    return this._tiptapEditor;
  }

  get empty() {
    const doc = this.tiptapEditor?.state.doc;

    // Makes sure the document has more than one empty paragraph
    return doc.childCount === 0 || (doc.childCount === 1 && doc.child(0).childCount === 0);
  }

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor, _serializer: serializer } = this;

    editor.commands.setContent(
      await serializer.deserialize({ schema: editor.schema, content: serializedContent }),
    );
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer } = this;

    return serializer.serialize({ schema: editor.schema, content: editor.getJSON() });
  }
}
