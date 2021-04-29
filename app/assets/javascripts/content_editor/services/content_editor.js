/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({ tiptapEditor, serializer }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
  }

  get tiptapEditor() {
    return this._tiptapEditor;
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
