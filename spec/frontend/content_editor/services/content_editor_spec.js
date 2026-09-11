import { builders } from 'prosemirror-test-builder';
import { closeHistory } from '@tiptap/pm/history';
import * as Y from 'yjs';
import { Awareness } from 'y-protocols/awareness';
import {
  ContentEditor,
  COLLABORATION_SYNC_TIMEOUT_MS,
} from '~/content_editor/services/content_editor';
import createCollaborationExtensions from '~/content_editor/services/create_collaboration_extensions';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Heading from '~/content_editor/extensions/heading';
import History from '~/content_editor/extensions/history';
import ListItem from '~/content_editor/extensions/list_item';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableHeader from '~/content_editor/extensions/table_header';
import TableRow from '~/content_editor/extensions/table_row';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor } from '../test_utils';

jest.mock('~/content_editor/services/code_block_language_loader');

describe('content_editor/services/content_editor', () => {
  let contentEditor;
  let tiptapEditor;
  let serializer;
  let deserializer;
  let eventHub;
  let doc;
  let p;
  const testMarkdown = '**bold text**';

  beforeEach(() => {
    tiptapEditor = createTestEditor();
    jest.spyOn(tiptapEditor, 'destroy');

    ({ doc, paragraph: p } = builders(tiptapEditor.schema));

    serializer = { serialize: jest.fn() };
    deserializer = { deserialize: jest.fn() };
    eventHub = eventHubFactory();
    contentEditor = new ContentEditor({
      tiptapEditor,
      serializer,
      deserializer,
      eventHub,
    });
  });

  const testDoc = () => doc(p('document'));

  const typeAtTheEnd = (text) => {
    const { state, view } = tiptapEditor;

    view.dispatch(state.tr.insertText(text, state.doc.content.size - 1));
  };

  describe('.dispose', () => {
    it('destroys the tiptapEditor', () => {
      expect(contentEditor.tiptapEditor.destroy).not.toHaveBeenCalled();

      contentEditor.dispose();

      expect(contentEditor.tiptapEditor.destroy).toHaveBeenCalled();
    });
  });

  describe('editable', () => {
    it('returns true when tiptapEditor is editable', () => {
      contentEditor.setEditable(true);

      expect(contentEditor.editable).toBe(true);
    });

    it('returns false when tiptapEditor is readonly', () => {
      contentEditor.setEditable(false);

      expect(contentEditor.editable).toBe(false);
    });
  });

  describe('when setSerializedContent succeeds', () => {
    it('sets the deserialized document in the tiptap editor object', async () => {
      const document = testDoc();

      deserializer.deserialize.mockResolvedValueOnce({ document });

      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });
  });

  describe('undo history', () => {
    let blockquote;
    let bulletList;
    let listItem;
    let heading;
    let codeBlock;
    let table;
    let tableRow;
    let tableHeader;
    let tableCell;

    const loadDocument = async (document, options) => {
      deserializer.deserialize.mockResolvedValueOnce({ document });

      await contentEditor.setSerializedContent(testMarkdown, options);
    };

    const pauseTyping = () => {
      tiptapEditor.view.dispatch(closeHistory(tiptapEditor.state.tr));
    };

    beforeEach(() => {
      tiptapEditor = createTestEditor({
        extensions: [
          History,
          Heading,
          Blockquote,
          BulletList,
          ListItem,
          CodeBlockHighlight,
          Table.configure({ eventHub }),
          TableRow,
          TableHeader,
          TableCell,
        ],
      });

      ({
        doc,
        paragraph: p,
        blockquote,
        bulletList,
        listItem,
        heading,
        codeBlock,
        table,
        tableRow,
        tableHeader,
        tableCell,
      } = builders(tiptapEditor.schema));

      contentEditor = new ContentEditor({ tiptapEditor, serializer, deserializer, eventHub });
    });

    it('does not undo the loaded document', async () => {
      const document = testDoc();

      await loadDocument(document);

      expect(tiptapEditor.commands.undo()).toBe(false);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });

    it('does not undo a loaded document with nested blocks', async () => {
      const document = doc(
        heading({ level: 1 }, 'Title'),
        blockquote(bulletList(listItem(p('quoted item'), bulletList(listItem(p('nested item')))))),
        table(
          tableRow(tableHeader(p('header 1')), tableHeader(p('header 2'))),
          tableRow(tableCell(p('cell 1')), tableCell(p('cell 2'))),
        ),
        codeBlock({ language: 'javascript' }, 'console.log(1);'),
      );

      await loadDocument(document);

      expect(tiptapEditor.commands.undo()).toBe(false);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });

    it('undoes and redoes only the edits made after the load', async () => {
      const document = testDoc();

      await loadDocument(document);
      typeAtTheEnd(' typed');

      expect(tiptapEditor.state.doc.textContent).toBe('document typed');

      expect(tiptapEditor.commands.undo()).toBe(true);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());

      expect(tiptapEditor.commands.undo()).toBe(false);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());

      expect(tiptapEditor.commands.redo()).toBe(true);
      expect(tiptapEditor.state.doc.textContent).toBe('document typed');
    });

    it('keeps a replacement of the document undoable when addToHistory is true', async () => {
      const first = testDoc();
      const second = doc(p('replacement'));

      await loadDocument(first);
      typeAtTheEnd(' typed');
      pauseTyping();
      await loadDocument(second, { addToHistory: true });

      expect(tiptapEditor.state.doc.toJSON()).toEqual(second.toJSON());

      expect(tiptapEditor.commands.undo()).toBe(true);
      expect(tiptapEditor.state.doc.textContent).toBe('document typed');

      expect(tiptapEditor.commands.undo()).toBe(true);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(first.toJSON());

      expect(tiptapEditor.commands.undo()).toBe(false);
    });
  });

  describe('when collaborating', () => {
    let collaborationProvider;

    const createCollaborativeEditor = (whenSynced, seed = jest.fn()) => {
      tiptapEditor = createTestEditor();
      collaborationProvider = { whenSynced, seed };

      contentEditor = new ContentEditor({
        tiptapEditor,
        serializer,
        deserializer,
        eventHub,
        collaborationProvider,
      });
    };

    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('seeds the document when the server elected this client', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: true }));

      await contentEditor.setSerializedContent(testMarkdown);

      expect(collaborationProvider.seed).toHaveBeenCalled();
    });

    it('seeds the document outside the undo history', async () => {
      const document = testDoc();

      createCollaborativeEditor(
        Promise.resolve({ seed: true }),
        jest.fn((seedDocument) => seedDocument()),
      );
      deserializer.deserialize.mockResolvedValueOnce({ document });
      jest.spyOn(tiptapEditor.view, 'dispatch');

      await contentEditor.setSerializedContent(testMarkdown);

      const [transaction] = tiptapEditor.view.dispatch.mock.calls[0];

      expect(transaction.getMeta('addToHistory')).toBe(false);
      expect(transaction.getMeta('preventUpdate')).toBe(true);
      expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });

    it('leaves the document alone when another client seeds it', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: false }));

      await contentEditor.setSerializedContent(testMarkdown);

      expect(collaborationProvider.seed).not.toHaveBeenCalled();
    });

    it('rejects rather than hanging when the initial sync never arrives', async () => {
      createCollaborativeEditor(new Promise(() => {}));

      const settled = contentEditor
        .setSerializedContent(testMarkdown)
        .then(() => null)
        .catch((error) => error.message);

      jest.advanceTimersByTime(COLLABORATION_SYNC_TIMEOUT_MS);

      await expect(settled).resolves.toMatch(/Timed out/);
    });

    it('does not reject when the sync arrives within the timeout', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: false }));

      const result = contentEditor.setSerializedContent(testMarkdown);

      jest.advanceTimersByTime(COLLABORATION_SYNC_TIMEOUT_MS * 2);

      await expect(result).resolves.toBeUndefined();
    });

    describe('with the Collaboration extension over a shared document', () => {
      let document;

      beforeEach(async () => {
        const ydoc = new Y.Doc();

        // The surface the editor and the collaboration extensions read from the provider.
        collaborationProvider = {
          doc: ydoc,
          awareness: new Awareness(ydoc),
          identityFor: () => null,
          whenSynced: Promise.resolve({ seed: true }),
          seed: jest.fn((seedDocument) => seedDocument()),
        };
        tiptapEditor = createTestEditor({
          extensions: createCollaborationExtensions({ provider: collaborationProvider }),
        });
        ({ doc, paragraph: p } = builders(tiptapEditor.schema));
        contentEditor = new ContentEditor({
          tiptapEditor,
          serializer,
          deserializer,
          eventHub,
          collaborationProvider,
        });

        document = testDoc();
        deserializer.deserialize.mockResolvedValueOnce({ document });

        await contentEditor.setSerializedContent(testMarkdown);
      });

      it('writes the seeded document into the shared document', () => {
        expect(collaborationProvider.doc.getXmlFragment('default').toString()).toBe(
          '<paragraph>document</paragraph>',
        );
      });

      it('keeps the seeded document when undo is pressed', () => {
        expect(tiptapEditor.commands.undo()).toBe(false);
        expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
      });

      it('undoes only the edits made after the seed', () => {
        typeAtTheEnd(' typed');

        expect(tiptapEditor.state.doc.textContent).toBe('document typed');

        expect(tiptapEditor.commands.undo()).toBe(true);
        expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());

        expect(tiptapEditor.commands.undo()).toBe(false);
        expect(tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
      });
    });
  });
});
