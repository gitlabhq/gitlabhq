import { builders } from 'prosemirror-test-builder';
import createEventHub from '~/helpers/event_hub_factory';
import Bold from '~/content_editor/extensions/bold';
import BulletList from '~/content_editor/extensions/bullet_list';
import ListItem from '~/content_editor/extensions/list_item';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableRow from '~/content_editor/extensions/table_row';
import TableHeader from '~/content_editor/extensions/table_header';
import { createTestEditor } from '../test_utils';

const eventHub = createEventHub();

describe('content_editor/extensions/table', () => {
  let tiptapEditor;
  let doc;
  let p;
  let table;
  let tableHeader;
  let tableCell;
  let tableRow;
  let initialDoc;
  let mockAlert;

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [
        Table.configure({ eventHub }),
        TableCell,
        TableRow,
        TableHeader,
        BulletList,
        Bold,
        ListItem,
      ],
    });

    ({
      doc,
      paragraph: p,
      table,
      tableCell,
      tableHeader,
      tableRow,
    } = builders(tiptapEditor.schema));

    initialDoc = doc(
      table(
        { isMarkdown: true },
        tableRow(tableHeader(p('This is')), tableHeader(p('a table'))),
        tableRow(tableCell(p('this is')), tableCell(p('the first row'))),
      ),
    );

    mockAlert = jest.fn();
  });

  it('triggers a warning (just once) if the table is markdown, but the changes in the document will render an HTML table instead', () => {
    tiptapEditor.commands.setContent(initialDoc.toJSON());

    eventHub.$on('alert', mockAlert);

    tiptapEditor.commands.setTextSelection({ from: 20, to: 22 });
    tiptapEditor.commands.toggleBulletList();

    jest.advanceTimersByTime(1001);
    expect(mockAlert).toHaveBeenCalledWith({
      message: expect.any(String),
      variant: 'warning',
    });

    mockAlert.mockReset();

    tiptapEditor.commands.setTextSelection({ from: 4, to: 6 });
    tiptapEditor.commands.toggleBulletList();

    jest.advanceTimersByTime(1001);
    expect(mockAlert).not.toHaveBeenCalled();
  });

  it('does not trigger a warning if the table is markdown, and the changes in the document can generate a markdown table', () => {
    tiptapEditor.commands.setContent(initialDoc.toJSON());

    tiptapEditor.on('alert', mockAlert);

    tiptapEditor.commands.setTextSelection({ from: 20, to: 22 });
    tiptapEditor.commands.toggleBold();

    jest.advanceTimersByTime(1001);
    expect(mockAlert).not.toHaveBeenCalled();
  });

  it('does not trigger any warnings if the table is not markdown', () => {
    initialDoc = doc(
      table(
        tableRow(tableHeader(p('This is')), tableHeader(p('a table'))),
        tableRow(tableCell(p('this is')), tableCell(p('the first row'))),
      ),
    );

    tiptapEditor.commands.setContent(initialDoc.toJSON());

    tiptapEditor.on('alert', mockAlert);

    tiptapEditor.commands.setTextSelection({ from: 20, to: 22 });
    tiptapEditor.commands.toggleBulletList();

    jest.advanceTimersByTime(1001);
    expect(mockAlert).not.toHaveBeenCalled();
  });
});
