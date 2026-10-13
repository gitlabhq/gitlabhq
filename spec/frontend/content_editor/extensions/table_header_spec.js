import { builders } from 'prosemirror-test-builder';
import { CellSelection } from '@tiptap/pm/tables';
import createEventHub from '~/helpers/event_hub_factory';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableRow from '~/content_editor/extensions/table_row';
import TableHeader from '~/content_editor/extensions/table_header';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/table_header', () => {
  let tiptapEditor;
  let doc;
  let p;
  let table;
  let tableRow;
  let tableHeader;
  let tableCell;

  const eventHub = createEventHub();

  const setTable = ({ secondColumnAlign = 'left' } = {}) => {
    const attrs = { align: secondColumnAlign };

    tiptapEditor.commands.setContent(
      doc(
        table(
          tableRow(tableHeader(p('Item')), tableHeader(attrs, p('Qty')), tableHeader(p('Price'))),
          tableRow(tableCell(p('Widget')), tableCell(attrs, p('3')), tableCell(p('9.99'))),
          tableRow(tableCell(p('Gadget')), tableCell(attrs, p('12')), tableCell(p('0.50'))),
        ),
        p('below'),
      ).toJSON(),
    );
  };

  const cells = () => {
    const rows = [];

    tiptapEditor.state.doc.descendants((node) => {
      if (node.type.name === 'tableRow') {
        const row = [];
        node.forEach((cell) => row.push(cell));
        rows.push(row);
      }

      return true;
    });

    return rows;
  };

  const alignments = () => cells().map((row) => row.map((cell) => cell.attrs.align));
  const texts = () => cells().map((row) => row.map((cell) => cell.textContent));

  const cellPosition = (text) => {
    let found;

    tiptapEditor.state.doc.descendants((node, pos) => {
      if (found === undefined && node.type.spec.tableRole && node.textContent === text) {
        found = pos;
      }

      return found === undefined;
    });

    return found;
  };

  const placeCursorAtEndOf = (text) => {
    let found;

    tiptapEditor.state.doc.descendants((node, pos) => {
      if (found === undefined && node.isText && node.text === text) {
        found = pos + text.length;
      }

      return found === undefined;
    });

    tiptapEditor.commands.setTextSelection(found);
  };

  const serialize = () =>
    new MarkdownSerializer().serialize({ doc: tiptapEditor.state.doc }).trim();

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [Table.configure({ eventHub }), TableCell, TableRow, TableHeader],
    });

    ({
      doc,
      paragraph: p,
      table,
      tableRow,
      tableHeader,
      tableCell,
    } = builders(tiptapEditor.schema));

    setTable();
  });

  describe.each`
    command                | from        | align
    ${'alignColumnLeft'}   | ${'center'} | ${'left'}
    ${'alignColumnCenter'} | ${'left'}   | ${'center'}
    ${'alignColumnRight'}  | ${'left'}   | ${'right'}
  `('$command', ({ command, from, align }) => {
    it.each(['Qty', '12'])('aligns every cell of the column when the cursor is in "%s"', (text) => {
      setTable({ secondColumnAlign: from });
      placeCursorAtEndOf(text);

      expect(tiptapEditor.commands[command]()).toBe(true);

      expect(alignments()).toEqual([
        ['left', align, 'left'],
        ['left', align, 'left'],
        ['left', align, 'left'],
      ]);
    });
  });

  it('keeps the text selection where the cursor was', () => {
    placeCursorAtEndOf('Qty');
    const selection = tiptapEditor.state.selection.toJSON();

    tiptapEditor.commands.alignColumnCenter();

    expect(selection.type).toBe('text');
    expect(tiptapEditor.state.selection.toJSON()).toEqual(selection);
  });

  it('lets typing continue in the same cell after aligning', () => {
    placeCursorAtEndOf('Qty');
    tiptapEditor.commands.alignColumnCenter();

    tiptapEditor.commands.insertContent(' (kg)');

    expect(texts()).toEqual([
      ['Item', 'Qty (kg)', 'Price'],
      ['Widget', '3', '9.99'],
      ['Gadget', '12', '0.50'],
    ]);
  });

  it.each`
    anchor     | head       | expected
    ${'Item'}  | ${'Qty'}   | ${['right', 'right', 'left']}
    ${'Price'} | ${'Qty'}   | ${['left', 'right', 'right']}
    ${'Item'}  | ${'Price'} | ${['right', 'right', 'right']}
  `(
    'aligns every column a cell selection from "$anchor" to "$head" spans',
    ({ anchor, head, expected }) => {
      const { tr } = tiptapEditor.state;
      tiptapEditor.view.dispatch(
        tr.setSelection(CellSelection.create(tr.doc, cellPosition(anchor), cellPosition(head))),
      );
      const selection = tiptapEditor.state.selection.toJSON();

      expect(tiptapEditor.commands.alignColumnRight()).toBe(true);

      expect(alignments()).toEqual([expected, expected, expected]);
      expect(tiptapEditor.state.selection.toJSON()).toEqual(selection);
    },
  );

  it('keeps a cell selection and aligns its column', () => {
    const { tr } = tiptapEditor.state;
    tiptapEditor.view.dispatch(
      tr.setSelection(CellSelection.create(tr.doc, cellPosition('Qty'), cellPosition('12'))),
    );

    expect(tiptapEditor.commands.alignColumnRight()).toBe(true);

    expect(tiptapEditor.state.selection).toBeInstanceOf(CellSelection);
    expect(tiptapEditor.state.selection.ranges).toHaveLength(3);
    expect(alignments()).toEqual([
      ['left', 'right', 'left'],
      ['left', 'right', 'left'],
      ['left', 'right', 'left'],
    ]);
  });

  it('does nothing when the cursor is outside a table', () => {
    placeCursorAtEndOf('below');
    const before = tiptapEditor.getJSON();

    expect(tiptapEditor.commands.alignColumnCenter()).toBe(false);
    expect(tiptapEditor.getJSON()).toEqual(before);
  });

  it('serializes the alignment as pipe table alignment markers', () => {
    placeCursorAtEndOf('Qty');
    tiptapEditor.commands.alignColumnCenter();
    placeCursorAtEndOf('Price');
    tiptapEditor.commands.alignColumnRight();

    expect(serialize()).toBe(
      `
| Item | Qty | Price |
|------|:---:|------:|
| Widget | 3 | 9.99 |
| Gadget | 12 | 0.50 |

below
      `.trim(),
    );
  });

  it('keeps the alignment of a table loaded from rendered markdown and can change it', () => {
    tiptapEditor.commands.setContent(`
      <table>
        <thead>
          <tr><th>Item</th><th align="center">Qty</th><th align="right">Price</th></tr>
        </thead>
        <tbody>
          <tr><td>Widget</td><td align="center">3</td><td align="right">9.99</td></tr>
        </tbody>
      </table>
    `);

    expect(alignments()).toEqual([
      ['left', 'center', 'right'],
      ['left', 'center', 'right'],
    ]);
    expect(serialize()).toBe(
      `
| Item | Qty | Price |
|------|:---:|------:|
| Widget | 3 | 9.99 |
      `.trim(),
    );

    placeCursorAtEndOf('Qty');
    tiptapEditor.commands.alignColumnLeft();

    expect(serialize()).toBe(
      `
| Item | Qty | Price |
|------|-----|------:|
| Widget | 3 | 9.99 |
      `.trim(),
    );
  });
});
