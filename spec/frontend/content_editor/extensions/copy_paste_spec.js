import { builders } from 'prosemirror-test-builder';
import { CellSelection } from '@tiptap/pm/tables';
import { GapCursor } from '@tiptap/pm/gapcursor';
import CopyPaste from '~/content_editor/extensions/copy_paste';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Loading, { findAllLoaders } from '~/content_editor/extensions/loading';
import Diagram from '~/content_editor/extensions/diagram';
import Frontmatter from '~/content_editor/extensions/frontmatter';
import Selection from '~/content_editor/extensions/selection';
import Heading from '~/content_editor/extensions/heading';
import HTMLComment from '~/content_editor/extensions/html_comment';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import OrderedList from '~/content_editor/extensions/ordered_list';
import ListItem from '~/content_editor/extensions/list_item';
import TaskList from '~/content_editor/extensions/task_list';
import TaskItem from '~/content_editor/extensions/task_item';
import Italic from '~/content_editor/extensions/italic';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableRow from '~/content_editor/extensions/table_row';
import TableHeader from '~/content_editor/extensions/table_header';
import { VARIANT_DANGER } from '~/alert';
import eventHubFactory from '~/helpers/event_hub_factory';
import { ALERT_EVENT } from '~/content_editor/constants';
import waitForPromises from 'helpers/wait_for_promises';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { createTestEditor, waitUntilNextDocTransaction } from '../test_utils';

const PARAGRAPH_HTML =
  '<p dir="auto">Some text with <strong>bold</strong> and <em>italic</em> text.</p>';

describe('content_editor/extensions/copy_paste', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let italic;
  let heading;
  let htmlComment;
  let horizontalRule;
  let codeBlock;
  let blockquote;
  let bulletList;
  let orderedList;
  let listItem;
  let taskList;
  let taskItem;
  let renderMarkdown;
  let resolveRenderMarkdownPromise;
  let resolveRenderMarkdownPromiseAndWait;

  let eventHub;
  const defaultData = { 'text/plain': '**bold text**' };

  beforeEach(() => {
    eventHub = eventHubFactory();
    renderMarkdown = jest.fn().mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveRenderMarkdownPromise = (data) => resolve({ body: data });
          resolveRenderMarkdownPromiseAndWait = (data) =>
            waitUntilNextDocTransaction({ tiptapEditor, action: () => resolve({ body: data }) });
        }),
    );

    jest.spyOn(eventHub, '$emit');

    tiptapEditor = createTestEditor({
      extensions: [
        Bold,
        Italic,
        Loading,
        Selection,
        CodeBlockHighlight,
        Diagram,
        Frontmatter,
        Heading,
        HTMLComment,
        HorizontalRule,
        Blockquote,
        BulletList,
        OrderedList,
        ListItem,
        TaskList,
        TaskItem,
        Table,
        TableCell,
        TableRow,
        TableHeader,
        CopyPaste.configure({ renderMarkdown, eventHub, serializer: new MarkdownSerializer() }),
      ],
    });

    ({
      doc,
      paragraph: p,
      bold,
      italic,
      heading,
      htmlComment,
      horizontalRule,
      codeBlock,
      blockquote,
      bulletList,
      orderedList,
      listItem,
      taskList,
      taskItem,
    } = builders(tiptapEditor.schema));
  });

  const buildClipboardEvent = ({ eventName = 'paste', data = {}, types = ['text/plain'] } = {}) => {
    return Object.assign(new Event(eventName), {
      clipboardData: {
        types,
        getData: jest.fn((type) => data[type] ?? defaultData[type]),
        setData: jest.fn(),
        clearData: jest.fn(),
      },
    });
  };

  const triggerPasteEventHandler = (event) => {
    return new Promise((resolve) => {
      tiptapEditor.view.someProp('handlePaste', (eventHandler) => {
        resolve(eventHandler(tiptapEditor.view, event));
      });
    });
  };

  it.each`
    types                                                | data                                                  | formatDesc
    ${['text/plain']}                                    | ${{}}                                                 | ${'plain text'}
    ${['text/plain', 'text/html']}                       | ${{}}                                                 | ${'html format'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "markdown" }' }} | ${'vscode markdown'}
    ${['text/plain', 'text/html', 'vscode-editor-data']} | ${{ 'vscode-editor-data': '{ "mode": "ruby" }' }}     | ${'vscode snippet'}
  `('handles $formatDesc', async ({ types, data }) => {
    expect(await triggerPasteEventHandler(buildClipboardEvent({ types, data }))).toBe(true);
  });

  describe.each`
    eventName | expectedDoc
    ${'cut'}  | ${() => doc(p())}
    ${'copy'} | ${() => doc(p('Some text with ', bold('bold'), ' and ', italic('italic'), ' text.'))}
  `('when $eventName event is triggered', ({ eventName, expectedDoc }) => {
    let event;
    beforeEach(() => {
      event = buildClipboardEvent({ eventName });

      jest.spyOn(event, 'preventDefault');
      jest.spyOn(event, 'stopPropagation');

      tiptapEditor.commands.insertContent(PARAGRAPH_HTML);
      tiptapEditor.commands.selectAll();
      tiptapEditor.view.dispatchEvent(event);
    });

    it('prevents default', () => {
      expect(event.preventDefault).toHaveBeenCalled();
      expect(event.stopPropagation).toHaveBeenCalled();
    });

    it('sets the clipboard data', () => {
      expect(event.clipboardData.setData).toHaveBeenCalledWith(
        'text/plain',
        'Some text with bold and italic text.',
      );
      expect(event.clipboardData.setData).toHaveBeenCalledWith('text/html', PARAGRAPH_HTML);
      expect(event.clipboardData.setData).toHaveBeenCalledWith(
        'text/x-gfm',
        'Some text with **bold** and _italic_ text.',
      );
    });

    it('modifies the document', () => {
      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc().toJSON());
    });
  });

  describe('when the selection contains an HTML comment', () => {
    beforeEach(() => {
      tiptapEditor.commands.setContent(
        doc(htmlComment({ description: 'my comment' }), p('Some text')).toJSON(),
      );
      tiptapEditor.commands.selectAll();
    });

    describe.each`
      eventName | expectedDoc
      ${'cut'}  | ${() => doc(p())}
      ${'copy'} | ${() => doc(htmlComment({ description: 'my comment' }), p('Some text'))}
    `('when $eventName event is triggered', ({ eventName, expectedDoc }) => {
      let event;

      beforeEach(() => {
        event = buildClipboardEvent({ eventName });

        jest.spyOn(event, 'preventDefault');

        tiptapEditor.view.dispatchEvent(event);
      });

      it('writes the comment to the HTML and markdown clipboard payloads', () => {
        expect(event.clipboardData.setData).toHaveBeenCalledWith('text/plain', 'Some text');
        expect(event.clipboardData.setData).toHaveBeenCalledWith(
          'text/html',
          '<comment data-description="my comment"></comment><p dir="auto">Some text</p>',
        );
        expect(event.clipboardData.setData).toHaveBeenCalledWith(
          'text/x-gfm',
          '<!--my comment-->\n\nSome text',
        );
        expect(event.preventDefault).toHaveBeenCalled();
      });

      it('modifies the document', () => {
        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc().toJSON());
      });
    });

    it('restores the comment when its HTML clipboard payload is pasted back', async () => {
      const event = buildClipboardEvent({ eventName: 'copy' });
      tiptapEditor.view.dispatchEvent(event);
      const clipboard = Object.fromEntries(event.clipboardData.setData.mock.calls);

      tiptapEditor.commands.setContent('<p></p>');

      await triggerPasteEventHandler(
        buildClipboardEvent({
          types: ['text/plain', 'text/html'],
          data: { 'text/plain': clipboard['text/plain'], 'text/html': clipboard['text/html'] },
        }),
      );
      await waitForPromises();

      expect(tiptapEditor.state.doc.toJSON()).toEqual(
        doc(htmlComment({ description: 'my comment' }), p('Some text')).toJSON(),
      );
    });
  });

  describe('when copying content with a single table cell', () => {
    it('sets the clipboard data properly', () => {
      const event = buildClipboardEvent({ eventName: 'copy' });

      tiptapEditor.commands.insertContent('<table><tr><td>Cell 1</td></tr></table>');
      tiptapEditor.commands.selectAll();
      tiptapEditor.view.dispatchEvent(event);

      expect(event.clipboardData.setData).toHaveBeenCalledWith('text/x-gfm', 'Cell 1');
    });
  });

  describe('when copying content with a table with multiple cells', () => {
    it('sets the clipboard data properly', () => {
      const event = buildClipboardEvent({ eventName: 'copy' });

      tiptapEditor.commands.insertContent('<table><tr><td>Cell 1</td><td>Cell 2</td></tr></table>');
      tiptapEditor.commands.selectAll();
      tiptapEditor.view.dispatchEvent(event);

      expect(event.clipboardData.setData).toHaveBeenCalledWith(
        'text/x-gfm',
        `<table>
<tr>
<td>Cell 1</td>
<td>Cell 2</td>
</tr>
</table>

`,
      );
    });
  });

  describe('table cell selections', () => {
    const findCellPositions = () => {
      const positions = [];
      tiptapEditor.state.doc.descendants((node, pos) => {
        if (node.type.name === 'tableCell' || node.type.name === 'tableHeader') {
          positions.push(pos);
        }
        return true;
      });
      return positions;
    };

    const selectCellRange = (anchorIndex, headIndex) => {
      const cells = findCellPositions();
      const { doc: stateDoc, tr } = tiptapEditor.state;
      tiptapEditor.view.dispatch(
        tr.setSelection(CellSelection.create(stateDoc, cells[anchorIndex], cells[headIndex])),
      );
    };

    const getTableRows = () => {
      const tableNode = tiptapEditor.state.doc.firstChild;
      const rows = [];
      tableNode.forEach((row) => {
        const cells = [];
        row.forEach((cell) => cells.push(cell.textContent));
        rows.push(cells);
      });
      return rows;
    };

    describe('when copying multiple table cells', () => {
      let event;

      beforeEach(() => {
        event = buildClipboardEvent({ eventName: 'copy' });

        tiptapEditor.commands.insertContent(
          '<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Cell 3</td><td>Cell 4</td></tr></table>',
        );
        selectCellRange(0, 1);
        tiptapEditor.view.dispatchEvent(event);
      });

      it('sets table-wrapped HTML in the clipboard', () => {
        const htmlCall = event.clipboardData.setData.mock.calls.find(
          ([format]) => format === 'text/html',
        );

        expect(htmlCall[1]).toMatch(/^<table><tbody><tr>/);
        expect(htmlCall[1]).toContain('Cell 1');
        expect(htmlCall[1]).toContain('Cell 2');
      });

      it('sets tab-separated plain text in the clipboard', () => {
        expect(event.clipboardData.setData).toHaveBeenCalledWith('text/plain', 'Cell 1\tCell 2');
      });
    });

    describe('when copying cells containing tabs or newlines', () => {
      it('replaces them with spaces in the plain text clipboard data', () => {
        const event = buildClipboardEvent({ eventName: 'copy' });

        const cellWith = (text) => ({
          type: 'tableCell',
          content: [{ type: 'paragraph', content: [{ type: 'text', text }] }],
        });

        tiptapEditor.commands.insertContent({
          type: 'table',
          content: [
            { type: 'tableRow', content: [cellWith('with\ttab'), cellWith('with\nnewline')] },
            { type: 'tableRow', content: [cellWith('C'), cellWith('D')] },
          ],
        });
        selectCellRange(0, 1);
        tiptapEditor.view.dispatchEvent(event);

        expect(event.clipboardData.setData).toHaveBeenCalledWith(
          'text/plain',
          'with tab\twith newline',
        );
      });
    });

    describe('when pasting table cells inside a table', () => {
      beforeEach(() => {
        tiptapEditor.commands.insertContent(
          '<table><tr><td>A</td><td>B</td></tr><tr><td>C</td><td>D</td></tr></table>',
        );
        // position cursor inside the first cell
        tiptapEditor.commands.setTextSelection(4);
      });

      it('distributes pasted cells across columns', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html': '<table><tr><td>X</td><td>Y</td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y'],
          ['C', 'D'],
        ]);
      });

      it('keeps an HTML comment inside a pasted cell', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html':
                '<table><tr><td><comment data-description="KEEP THIS COMMENT"></comment><p>X</p></td><td><p>Y</p></td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y'],
          ['C', 'D'],
        ]);

        const comments = [];
        tiptapEditor.state.doc.descendants((node) => {
          if (node.type.name === 'htmlComment') comments.push(node.attrs.description);
          return true;
        });
        expect(comments).toEqual(['KEEP THIS COMMENT']);
      });

      it('auto-expands the table when pasting more cells than remaining columns', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY\tZ',
              'text/html': '<table><tr><td>X</td><td>Y</td><td>Z</td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y', 'Z'],
          ['C', 'D', ''],
        ]);
      });

      it('distributes pasted cells when the table HTML is wrapped in div elements', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html':
                '<div><div data-sticky-header="true"><table><tbody><tr><td>X</td><td>Y</td></tr></tbody></table></div></div>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y'],
          ['C', 'D'],
        ]);
      });

      it('distributes pasted cells when the clipboard HTML contains orphan tr elements', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html', 'text/x-gfm'],
            data: {
              'text/plain': 'X\tY',
              'text/html': '<tr><td><p>X</p></td><td><p>Y</p></td></tr>',
              'text/x-gfm': '<table><tr><td>X</td><td>Y</td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y'],
          ['C', 'D'],
        ]);
      });

      it('sanitizes pasted table HTML', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html':
                '<table><tr><td><a href="javascript:alert(1)">X</a></td><td><img src="x" onerror="alert(1)">Y</td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        // eslint-disable-next-line no-script-url
        expect(JSON.stringify(tiptapEditor.state.doc.toJSON())).not.toContain('javascript:');
      });

      it('strips stray div and span wrappers from external table HTML', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html':
                '<table><tr><td><div><span>X</span></div></td><td><div><span>Y</span></div></td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['X', 'Y'],
          ['C', 'D'],
        ]);

        const docJSON = JSON.stringify(tiptapEditor.state.doc.toJSON());
        expect(docJSON).not.toContain('"div"');
        expect(docJSON).not.toContain('"span"');
      });

      it('does not use the table paste handler when pasting content without table cells', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'plain text',
              'text/html': '<p>plain text</p>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(findAllLoaders(tiptapEditor.state)).toHaveLength(1);
      });

      describe('clipboard menu commands', () => {
        const mockClipboardRead = ({ gfm, html, text } = {}) => {
          const items = [];
          const makeItem = (type, content) => ({
            types: [type],
            getType: jest.fn().mockResolvedValue({ text: () => Promise.resolve(content) }),
          });
          if (gfm !== undefined) items.push(makeItem('text/x-gfm', gfm));
          if (html !== undefined) items.push(makeItem('text/html', html));
          if (text !== undefined) items.push(makeItem('text/plain', text));

          jest.spyOn(navigator.clipboard, 'read').mockResolvedValue(items);
        };

        describe('pasteFromClipboardIntoCell', () => {
          describe('when the clipboard contains table HTML', () => {
            beforeEach(() => {
              mockClipboardRead({
                html: '<table><tr><td>X</td><td>Y</td></tr></table>',
                text: 'X\tY',
              });
            });

            it('pastes clipboard table HTML as a nested table inside the cell', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoCell();
              await waitForPromises();

              expect(getTableRows()).toEqual([
                ['XYA', 'B'],
                ['C', 'D'],
              ]);

              const docJSON = JSON.stringify(tiptapEditor.state.doc.toJSON());
              expect(docJSON.match(/"type":"table"/g)).toHaveLength(2);
            });
          });

          describe('when the clipboard exposes text/x-gfm', () => {
            beforeEach(() => {
              mockClipboardRead({
                gfm: '**bold text**',
                html: '<p>ignored</p>',
                text: 'ignored',
              });
            });

            it('prefers text/x-gfm over HTML', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoCell();
              await waitForPromises();

              expect(renderMarkdown).toHaveBeenCalledWith('**bold text**');
            });
          });

          describe('when the clipboard is empty', () => {
            beforeEach(() => {
              mockClipboardRead();
            });

            it('does nothing', async () => {
              const docBefore = tiptapEditor.state.doc.toJSON();

              tiptapEditor.commands.pasteFromClipboardIntoCell();
              await waitForPromises();

              expect(tiptapEditor.state.doc.toJSON()).toEqual(docBefore);
            });
          });

          describe('when reading the clipboard fails', () => {
            beforeEach(() => {
              jest.spyOn(navigator.clipboard, 'read').mockRejectedValue(new Error('denied'));
            });

            it('emits an alert', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoCell();
              await waitForPromises();

              expect(eventHub.$emit).toHaveBeenCalledWith(
                ALERT_EVENT,
                expect.objectContaining({ variant: VARIANT_DANGER }),
              );
            });
          });
        });

        describe('pasteFromClipboardIntoTable', () => {
          describe('when the clipboard contains table HTML', () => {
            beforeEach(() => {
              mockClipboardRead({
                html: '<table><tr><td>X</td><td>Y</td></tr></table>',
                text: 'X\tY',
              });
            });

            it('distributes clipboard table cells across the table', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoTable();
              await waitForPromises();

              expect(getTableRows()).toEqual([
                ['X', 'Y'],
                ['C', 'D'],
              ]);
            });
          });

          describe('when the clipboard has no table cells', () => {
            beforeEach(() => {
              mockClipboardRead({ html: '<p>plain text</p>', text: 'plain text' });
            });

            it('falls back to a regular paste', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoTable();
              await waitForPromises();

              expect(tiptapEditor.state.doc.textContent).toContain('plain text');
              expect(getTableRows()).toEqual([
                ['plain textA', 'B'],
                ['C', 'D'],
              ]);
            });
          });

          describe('when the clipboard exposes text/x-gfm for non-table content', () => {
            beforeEach(() => {
              mockClipboardRead({ gfm: '**bold text**', text: 'ignored' });
            });

            it('prefers text/x-gfm over plain text', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoTable();
              await waitForPromises();

              expect(renderMarkdown).toHaveBeenCalledWith('**bold text**');
            });
          });

          describe('when reading the clipboard fails', () => {
            beforeEach(() => {
              jest.spyOn(navigator.clipboard, 'read').mockRejectedValue(new Error('denied'));
            });

            it('emits an alert', async () => {
              tiptapEditor.commands.pasteFromClipboardIntoTable();
              await waitForPromises();

              expect(eventHub.$emit).toHaveBeenCalledWith(
                ALERT_EVENT,
                expect.objectContaining({ variant: VARIANT_DANGER }),
              );
            });
          });
        });

        describe('shortcut: Mod-Alt-v', () => {
          beforeEach(() => {
            window.isSecureContext = true;
            mockClipboardRead({
              html: '<table><tr><td>X</td><td>Y</td></tr></table>',
              text: 'X\tY',
            });
          });

          it('pastes the clipboard table as a nested table inside the cell', async () => {
            tiptapEditor.commands.keyboardShortcut('Mod-Alt-v');
            await waitForPromises();

            const docJSON = JSON.stringify(tiptapEditor.state.doc.toJSON());
            expect(docJSON.match(/"type":"table"/g)).toHaveLength(2);
          });

          it('does nothing when the Clipboard API is unavailable', async () => {
            window.isSecureContext = false;
            const docBefore = tiptapEditor.state.doc.toJSON();

            tiptapEditor.commands.keyboardShortcut('Mod-Alt-v');
            await waitForPromises();

            expect(tiptapEditor.state.doc.toJSON()).toEqual(docBefore);
            expect(navigator.clipboard.read).not.toHaveBeenCalled();
          });
        });
      });

      it('uses the markdown-based paste path when pasting a single cell', async () => {
        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html', 'text/x-gfm'],
            data: {
              'text/plain': 'bold text',
              'text/html': '<tr><td><p><strong>bold text</strong></p></td></tr>',
              'text/x-gfm': '**bold text**',
            },
          }),
        );

        // gfmContent path returns true and processes markdown asynchronously
        expect(result).toBe(true);
        expect(findAllLoaders(tiptapEditor.state)).toHaveLength(1);
        expect(getTableRows()).not.toEqual([
          ['bold text', 'B'],
          ['C', 'D'],
        ]);
      });
    });

    describe('when pasting table cells outside a table', () => {
      it('falls back to the regular paste handler', async () => {
        tiptapEditor.commands.setContent('<p>Some text</p>');
        tiptapEditor.commands.setTextSelection(1);

        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'X\tY',
              'text/html': '<table><tr><td>X</td><td>Y</td></tr></table>',
            },
          }),
        );

        expect(result).toBe(true);
        expect(findAllLoaders(tiptapEditor.state)).toHaveLength(1);
      });
    });

    describe('round-trip: copying cells in the editor and pasting into a table', () => {
      it('distributes the copied cells across the target row', async () => {
        const copyEvent = buildClipboardEvent({ eventName: 'copy' });

        tiptapEditor.commands.insertContent(
          '<table><tr><td>data</td><td>banana</td></tr><tr><td>C</td><td>D</td></tr></table>',
        );
        selectCellRange(0, 1);
        tiptapEditor.view.dispatchEvent(copyEvent);

        const clipboard = Object.fromEntries(copyEvent.clipboardData.setData.mock.calls);

        tiptapEditor.commands.setContent(
          '<table><tr><td>A</td><td>B</td></tr><tr><td>C</td><td>D</td></tr></table>',
        );
        tiptapEditor.commands.setTextSelection(4);

        const result = await triggerPasteEventHandler(
          buildClipboardEvent({
            types: Object.keys(clipboard),
            data: clipboard,
          }),
        );

        expect(result).toBe(true);
        expect(getTableRows()).toEqual([
          ['data', 'banana'],
          ['C', 'D'],
        ]);
      });
    });
  });

  it('does not handle pasting when textContent is empty (eg. images)', async () => {
    expect(
      await triggerPasteEventHandler(
        buildClipboardEvent({
          types: ['text/plain'],
          data: { 'text/plain': '' },
        }),
      ),
    ).toBe(false);
  });

  describe('shortcut: Mod-Alt-v outside a table', () => {
    it('does nothing and lets the event fall through', async () => {
      window.isSecureContext = true;
      jest.spyOn(navigator.clipboard, 'read');

      tiptapEditor.commands.insertContent('<p>Some text</p>');
      const docBefore = tiptapEditor.state.doc.toJSON();

      tiptapEditor.commands.keyboardShortcut('Mod-Alt-v');
      await waitForPromises();

      expect(tiptapEditor.state.doc.toJSON()).toEqual(docBefore);
      expect(navigator.clipboard.read).not.toHaveBeenCalled();
    });
  });

  describe('when pasting raw markdown source', () => {
    it('shows a loading indicator while markdown is being processed', async () => {
      await triggerPasteEventHandler(buildClipboardEvent());

      expect(findAllLoaders(tiptapEditor.state)).toHaveLength(1);
    });

    describe('when some content is added before the markdown is processed', () => {
      it('pastes in the correct position', async () => {
        const expectedDoc = doc(p(bold('some markdown'), 'some content'));
        const resolvedValue = '<strong>some markdown</strong>';

        await triggerPasteEventHandler(buildClipboardEvent());

        tiptapEditor.commands.insertContent('some content');

        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when rendering markdown succeeds', () => {
      let resolvedValue;

      beforeEach(() => {
        resolvedValue = '<strong>bold text</strong>';
      });

      it('transforms pasted text into a prosemirror node', async () => {
        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandler(buildClipboardEvent());
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });

      describe('when pasting inline content in an existing paragraph', () => {
        it('inserts the inline content next to the existing paragraph content', async () => {
          const expectedDoc = doc(p('Initial text and', bold('bold text')));

          tiptapEditor.commands.setContent('Initial text and ');

          await triggerPasteEventHandler(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });

      describe('when pasting inline content and there is text selected', () => {
        it('inserts the block content after the existing paragraph', async () => {
          const expectedDoc = doc(p('Initial text', bold('bold text')));

          tiptapEditor.commands.setContent('Initial text and ');
          tiptapEditor.commands.setTextSelection({ from: 13, to: 17 });

          await triggerPasteEventHandler(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });

      describe('when pasting block content in an existing paragraph', () => {
        beforeEach(() => {
          resolvedValue = '<h1>Heading</h1><p><strong>bold text</strong></p>';
        });

        it('inserts the block content after the existing paragraph', async () => {
          const expectedDoc = doc(
            p('Initial text and'),
            heading({ level: 1 }, 'Heading'),
            p(bold('bold text')),
          );

          tiptapEditor.commands.setContent('Initial text and ');

          await triggerPasteEventHandler(buildClipboardEvent());
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });

      describe('when pasting over a fully selected document', () => {
        beforeEach(async () => {
          tiptapEditor.commands.setContent('<p>Some text</p>');
          tiptapEditor.commands.selectAll();

          await triggerPasteEventHandler(buildClipboardEvent());
        });

        it('replaces the document with only the pasted inline content', async () => {
          const expectedDoc = doc(p(bold('bold text')));

          resolveRenderMarkdownPromise(resolvedValue);
          await waitForPromises();

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });

        it('removes the loading indicator', async () => {
          resolveRenderMarkdownPromise(resolvedValue);
          await waitForPromises();

          expect(findAllLoaders(tiptapEditor.state)).toHaveLength(0);
        });

        describe('when the pasted content contains multiple blocks', () => {
          beforeEach(() => {
            resolvedValue = '<h1>Heading</h1><p><strong>bold text</strong></p>';
          });

          it('replaces the document with only the pasted content', async () => {
            const expectedDoc = doc(heading({ level: 1 }, 'Heading'), p(bold('bold text')));

            resolveRenderMarkdownPromise(resolvedValue);
            await waitForPromises();

            expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
          });
        });
      });

      describe('when pasting at a gap cursor at the start of the document', () => {
        beforeEach(async () => {
          tiptapEditor.commands.setContent('<hr><p></p>');
          tiptapEditor.view.dispatch(
            tiptapEditor.state.tr.setSelection(new GapCursor(tiptapEditor.state.doc.resolve(0))),
          );

          await triggerPasteEventHandler(buildClipboardEvent());
        });

        it('inserts the content at the start of the document and removes the loading indicator', async () => {
          const expectedDoc = doc(p(bold('bold text')), horizontalRule(), p());

          resolveRenderMarkdownPromise(resolvedValue);
          await waitForPromises();

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
          expect(findAllLoaders(tiptapEditor.state)).toHaveLength(0);
        });
      });

      describe('when the loading indicator is deleted before the markdown is processed', () => {
        beforeEach(async () => {
          tiptapEditor.commands.setContent('<p>Some text</p>');

          await triggerPasteEventHandler(buildClipboardEvent());

          tiptapEditor.commands.selectAll();
          tiptapEditor.commands.deleteSelection();
        });

        it('does not insert the pasted content and leaves no loading indicator', async () => {
          resolveRenderMarkdownPromise(resolvedValue);
          await waitForPromises();

          expect(tiptapEditor.state.doc.toJSON()).toEqual(doc(p()).toJSON());
          expect(findAllLoaders(tiptapEditor.state)).toHaveLength(0);
        });
      });
    });

    describe('when pasting html content', () => {
      it('strips out any stray div, pre, span tags', async () => {
        const resolvedValue =
          '<div><span dir="auto"><strong>bold text</strong></span></div><pre><code>some code</code></pre>';

        const expectedDoc = doc(p(bold('bold text')), p('some code'));

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/html'],
            data: {
              'text/html':
                '<div><span dir="auto"><strong>bold text</strong></span></div><pre><code>some code</code></pre>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting text/x-gfm', () => {
      it('processes the content as markdown, even if html content exists', async () => {
        const resolvedValue = '<strong>bold text</strong>';
        const expectedDoc = doc(p(bold('bold text')));

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/x-gfm', 'text/plain', 'text/html'],
            data: {
              'text/x-gfm': '**bold text**',
              'text/plain': 'irrelevant text',
              'text/html': '<div>some random irrelevant html</div>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting into a block of the same kind as the pasted content', () => {
      const LIST_ITEM = { gfm: '* one', html: '<ul dir="auto">\n<li>one</li>\n</ul>' };

      // Sets the document and places the cursor at the <a> tag in the builder
      const setContentWithCursor = (documentNode) => {
        tiptapEditor.commands.setContent(documentNode.toJSON());
        tiptapEditor.commands.setTextSelection(documentNode.tag.a);
      };

      const pasteMarkdown = async ({ gfm, html }) => {
        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/x-gfm', 'text/plain', 'text/html'],
            data: { 'text/x-gfm': gfm, 'text/plain': gfm, 'text/html': html },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(html);
      };

      it.each`
        where                     | initialDoc                                                                    | expectedDoc
        ${'at the end of the'}    | ${() => doc(bulletList(listItem(p('item one')), listItem(p('item two<a>'))))} | ${() => doc(bulletList(listItem(p('item one')), listItem(p('item twoone'))))}
        ${'at the start of the'}  | ${() => doc(bulletList(listItem(p('item one')), listItem(p('<a>item two'))))} | ${() => doc(bulletList(listItem(p('item one')), listItem(p('oneitem two'))))}
        ${'in the middle of the'} | ${() => doc(bulletList(listItem(p('item one')), listItem(p('item <a>two'))))} | ${() => doc(bulletList(listItem(p('item one')), listItem(p('item onetwo'))))}
        ${'into an empty'}        | ${() => doc(bulletList(listItem(p('item one')), listItem(p('<a>'))))}         | ${() => doc(bulletList(listItem(p('item one')), listItem(p('one'))))}
      `(
        'inserts a copied list item inline $where list item under the cursor',
        async ({ initialDoc, expectedDoc }) => {
          setContentWithCursor(initialDoc());

          await pasteMarkdown(LIST_ITEM);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc().toJSON());
        },
      );

      it.each`
        description          | gfm            | html
        ${'an ordered list'} | ${'1. one'}    | ${'<ol dir="auto">\n<li>one</li>\n</ol>'}
        ${'a task list'}     | ${'* [ ] one'} | ${'<ul class="task-list" dir="auto">\n<li class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" disabled> one</li>\n</ul>'}
      `('treats an item copied from $description as a list item too', async ({ gfm, html }) => {
        setContentWithCursor(doc(bulletList(listItem(p('item one')), listItem(p('item two<a>')))));

        await pasteMarkdown({ gfm, html });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('item one')), listItem(p('item twoone')))).toJSON(),
        );
      });

      it('inserts a list item copied as HTML from a web page inline too', async () => {
        setContentWithCursor(doc(bulletList(listItem(p('item one')), listItem(p('item two<a>')))));

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': 'one',
              'text/html': "<meta charset='utf-8'><ul><li>one</li></ul>",
            },
          }),
        );
        await waitForPromises();

        expect(renderMarkdown).not.toHaveBeenCalled();
        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('item one')), listItem(p('item twoone')))).toJSON(),
        );
      });

      it('inserts a bullet list item inline into a task list item', async () => {
        setContentWithCursor(doc(taskList(taskItem(p('task one')), taskItem(p('task two<a>')))));

        await pasteMarkdown(LIST_ITEM);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(taskList(taskItem(p('task one')), taskItem(p('task twoone')))).toJSON(),
        );
      });

      it('inserts an ordered list item inline into an ordered list item', async () => {
        setContentWithCursor(doc(orderedList(listItem(p('step one')), listItem(p('step two<a>')))));

        await pasteMarkdown({ gfm: '1. one', html: '<ol dir="auto">\n<li>one</li>\n</ol>' });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(orderedList(listItem(p('step one')), listItem(p('step twoone')))).toJSON(),
        );
      });

      it('adds the remaining items as siblings when several items are pasted', async () => {
        setContentWithCursor(doc(bulletList(listItem(p('item one')), listItem(p('item two<a>')))));

        await pasteMarkdown({
          gfm: '* a\n* b',
          html: '<ul dir="auto">\n<li>a</li>\n<li>b</li>\n</ul>',
        });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(
            bulletList(listItem(p('item one')), listItem(p('item twoa')), listItem(p('b'))),
          ).toJSON(),
        );
      });

      it('inserts inline into a nested list item', async () => {
        setContentWithCursor(
          doc(bulletList(listItem(p('outer'), bulletList(listItem(p('inner<a>')))))),
        );

        await pasteMarkdown(LIST_ITEM);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('outer'), bulletList(listItem(p('innerone')))))).toJSON(),
        );
      });

      it('keeps the sub-items of the list item under the cursor', async () => {
        setContentWithCursor(
          doc(bulletList(listItem(p('item<a>'), bulletList(listItem(p('sub-item')))))),
        );

        await pasteMarkdown(LIST_ITEM);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('itemone'), bulletList(listItem(p('sub-item')))))).toJSON(),
        );
      });

      it('continues the text after the cursor in the last pasted block', async () => {
        setContentWithCursor(doc(bulletList(listItem(p('alpha<a> beta')), listItem(p('gamma')))));

        await pasteMarkdown({
          gfm: '* outer\n  * inner',
          html: '<ul dir="auto">\n<li>outer\n<ul>\n<li>inner</li>\n</ul>\n</li>\n</ul>',
        });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(
            bulletList(
              listItem(p('alphaouter'), bulletList(listItem(p('inner beta')))),
              listItem(p('gamma')),
            ),
          ).toJSON(),
        );
      });

      it('keeps the marks of the pasted content', async () => {
        setContentWithCursor(doc(bulletList(listItem(p('item<a>')))));

        await pasteMarkdown({
          gfm: '* **bold** one',
          html: '<ul dir="auto">\n<li><strong>bold</strong> one</li>\n</ul>',
        });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('item', bold('bold'), ' one')))).toJSON(),
        );
      });

      it('replaces the selected text with the pasted item content', async () => {
        const initialDoc = doc(bulletList(listItem(p('item one')), listItem(p('item <a>two<b>'))));
        tiptapEditor.commands.setContent(initialDoc.toJSON());
        tiptapEditor.commands.setTextSelection({ from: initialDoc.tag.a, to: initialDoc.tag.b });

        await pasteMarkdown(LIST_ITEM);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('item one')), listItem(p('item one')))).toJSON(),
        );
      });

      it('inserts at the loading indicator when content is typed before the markdown is processed', async () => {
        setContentWithCursor(doc(bulletList(listItem(p('item<a>')))));

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/x-gfm', 'text/plain', 'text/html'],
            data: {
              'text/x-gfm': LIST_ITEM.gfm,
              'text/plain': LIST_ITEM.gfm,
              'text/html': LIST_ITEM.html,
            },
          }),
        );
        tiptapEditor.commands.insertContent(' typed');
        await resolveRenderMarkdownPromiseAndWait(LIST_ITEM.html);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(bulletList(listItem(p('itemone typed')))).toJSON(),
        );
      });

      it('inserts quoted text inline into the blockquote under the cursor', async () => {
        setContentWithCursor(doc(blockquote(p('existing <a>quote'))));

        await pasteMarkdown({
          gfm: '> quoted',
          html: '<blockquote dir="auto">\n<p dir="auto">quoted</p>\n</blockquote>',
        });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(blockquote(p('existing quotedquote'))).toJSON(),
        );
      });

      it('inserts heading text inline into the heading under the cursor', async () => {
        setContentWithCursor(doc(heading({ level: 2 }, 'Some <a>heading')));

        await pasteMarkdown({ gfm: '# Title', html: '<h1 dir="auto">Title</h1>' });

        expect(tiptapEditor.state.doc.toJSON()).toEqual(
          doc(heading({ level: 2 }, 'Some Titleheading')).toJSON(),
        );
      });

      describe('when the cursor is not in the same kind of block', () => {
        it('still pastes a list item as a list into an empty paragraph', async () => {
          setContentWithCursor(doc(p('<a>')));

          await pasteMarkdown(LIST_ITEM);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(bulletList(listItem(p('one')))).toJSON(),
          );
        });

        it('still pastes a list item as a list block inside a paragraph', async () => {
          setContentWithCursor(doc(p('hello <a>world')));

          await pasteMarkdown(LIST_ITEM);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(p('hello '), bulletList(listItem(p('one'))), p('world')).toJSON(),
          );
        });

        it('still pastes a list item as a list block inside a blockquote paragraph', async () => {
          setContentWithCursor(doc(blockquote(p('quote <a>text'))));

          await pasteMarkdown(LIST_ITEM);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(blockquote(p('quote '), bulletList(listItem(p('one'))), p('text'))).toJSON(),
          );
        });

        it('still pastes a heading as a block inside a paragraph', async () => {
          setContentWithCursor(doc(p('hello <a>world')));

          await pasteMarkdown({ gfm: '# Title', html: '<h1 dir="auto">Title</h1>' });

          expect(tiptapEditor.state.doc.toJSON()).toEqual(
            doc(p('hello '), heading({ level: 1 }, 'Title'), p('world')).toJSON(),
          );
        });
      });
    });

    describe('when pasting a single code block with lang=markdown', () => {
      it('process the textContent as markdown, ignoring the htmlContent', async () => {
        const resolvedValue = '<ul><li>Cat</li><li>Dog</li><li>Turtle</li></ul>';
        const expectedDoc = doc(
          bulletList(listItem(p('Cat')), listItem(p('Dog')), listItem(p('Turtle'))),
        );

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['text/plain', 'text/html'],
            data: {
              'text/plain': '- Cat\n- Dog\n- Turtle\n',
              'text/html': `<meta charset='utf-8'><pre class="code highlight" lang="markdown"><span id="LC1" class="line" lang="markdown"><span class="p">-</span> Cat</span>\n<span id="LC2" class="line" lang="markdown"><span class="p">-</span> Dog</span>\n<span id="LC3" class="line" lang="markdown"><span class="p">-</span> Turtle</span>\n</pre>`,
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });

    describe('when pasting vscode-editor-data', () => {
      it('pastes the content as a code block', async () => {
        const resolvedValue =
          '<div class="gl-relative markdown-code-block js-markdown-code">&#x000A;<pre data-sourcepos="1:1-3:3" data-canonical-lang="ruby" class="code highlight js-syntax-highlight language-ruby" lang="ruby" v-pre="true"><code><span id="LC1" class="line" lang="ruby"><span class="nb">puts</span> <span class="s2">"Hello World"</span></span></code></pre>&#x000A;<copy-code></copy-code>&#x000A;</div>';

        const expectedDoc = doc(
          codeBlock(
            { language: 'ruby', class: 'code highlight js-syntax-highlight language-ruby' },
            'puts "Hello World"',
          ),
        );

        await triggerPasteEventHandler(
          buildClipboardEvent({
            types: ['vscode-editor-data', 'text/plain', 'text/html'],
            data: {
              'vscode-editor-data': '{ "version": 1, "mode": "ruby" }',
              'text/plain': 'puts "Hello World"',
              'text/html':
                '<meta charset=\'utf-8\'><div style="color: #d4d4d4;background-color: #1e1e1e;font-family: \'Fira Code\', Menlo, Monaco, \'Courier New\', monospace, Menlo, Monaco, \'Courier New\', monospace;font-weight: normal;font-size: 14px;line-height: 21px;white-space: pre;"><div><span style="color: #dcdcaa;">puts</span><span style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Hello world"</span></div></div>',
            },
          }),
        );
        await resolveRenderMarkdownPromiseAndWait(resolvedValue);

        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
      });

      describe('when the language is markdown', () => {
        it('pastes as regular markdown', async () => {
          const resolvedValue = '<p><strong>bold text</strong></p>';

          const expectedDoc = doc(p(bold('bold text')));

          await triggerPasteEventHandler(
            buildClipboardEvent({
              types: ['vscode-editor-data', 'text/plain', 'text/html'],
              data: {
                'vscode-editor-data': '{ "version": 1, "mode": "markdown" }',
                'text/plain': '**bold text**',
                'text/html': '<p><strong>bold text</strong></p>',
              },
            }),
          );
          await resolveRenderMarkdownPromiseAndWait(resolvedValue);

          expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        });
      });
    });

    describe('when rendering markdown fails', () => {
      beforeEach(() => {
        renderMarkdown.mockRejectedValueOnce();
      });

      it(`triggers ${ALERT_EVENT} event`, async () => {
        await triggerPasteEventHandler(buildClipboardEvent());
        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith(ALERT_EVENT, {
          message: expect.any(String),
          variant: VARIANT_DANGER,
        });
      });

      it('removes the loading indicator', async () => {
        await triggerPasteEventHandler(buildClipboardEvent());
        await waitForPromises();

        expect(findAllLoaders(tiptapEditor.state)).toHaveLength(0);
      });
    });
  });
});
