import { DocAttrStep } from '@tiptap/pm/transform';

export const COLLABORATION_SYNC_TIMEOUT_MS = 10000;

const SYNC_TIMEOUT_ERROR = 'Timed out waiting for the collaborative session to sync';

/* eslint-disable no-underscore-dangle */
export class ContentEditor {
  constructor({
    tiptapEditor,
    serializer,
    deserializer,
    assetResolver,
    eventHub,
    drawioEnabled,
    supportsTableOfContents,
    codeSuggestionsConfig,
    autocompleteHelper,
    collaborationProvider = null,
  }) {
    this._tiptapEditor = tiptapEditor;
    this._serializer = serializer;
    this._deserializer = deserializer;
    this._eventHub = eventHub;
    this._assetResolver = assetResolver;
    this._autocompleteHelper = autocompleteHelper;
    this._collaborationProvider = collaborationProvider;

    this.codeSuggestionsConfig = codeSuggestionsConfig;
    this.drawioEnabled = drawioEnabled;
    this.supportsTableOfContents = supportsTableOfContents;
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

  get editable() {
    return this.tiptapEditor.isEditable;
  }

  get isCollaborative() {
    return Boolean(this._collaborationProvider);
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

  resolveIframeSrc(canonicalSrc) {
    return this._assetResolver.resolveIframeSrc(canonicalSrc);
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

  async _whenSyncedOrTimeout() {
    let timeoutId;

    const timeout = new Promise((_resolve, reject) => {
      timeoutId = setTimeout(
        () => reject(new Error(SYNC_TIMEOUT_ERROR)),
        COLLABORATION_SYNC_TIMEOUT_MS,
      );
    });

    try {
      return await Promise.race([this._collaborationProvider.whenSynced, timeout]);
    } finally {
      clearTimeout(timeoutId);
    }
  }

  async setSerializedContent(serializedContent) {
    const { _tiptapEditor: editor } = this;

    if (this._collaborationProvider) {
      const { seed } = await this._whenSyncedOrTimeout();

      // Every other client receives the document through the CRDT.
      if (!seed) return;

      await this._collaborationProvider.seed(async () => {
        const { document } = await this.deserialize(serializedContent);

        if (document) {
          editor.commands.setContent(document.toJSON(), false);
        }
      });

      return;
    }

    const { document } = await this.deserialize(serializedContent);
    const { doc } = editor.state;

    if (document) {
      let tr = editor.state.tr.replaceWith(0, doc.content.size, document);
      for (const [key, value] of Object.entries(document.attrs)) {
        tr = tr.step(new DocAttrStep(key, value));
      }
      editor.view.dispatch(tr.setMeta('preventUpdate', true));
    }
  }

  getSerializedContent() {
    const { _tiptapEditor: editor, _serializer: serializer } = this;
    const { doc } = editor.state;

    return serializer.serialize({ doc });
  }
}
