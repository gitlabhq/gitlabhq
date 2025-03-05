import { builders } from 'prosemirror-test-builder';
import Time from '~/content_editor/extensions/time';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/html_marks', () => {
  let tiptapEditor;
  let doc;
  let time;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Time] });

    ({ time, paragraph: p, doc } = builders(tiptapEditor.schema));
  });

  it('parses a time tag correctly', () => {
    tiptapEditor.commands.setContent(`
      <time title="November 2, 2023" datetime="2023-11-02">
        November 2, 2023
      </time>
    `);
    expect(tiptapEditor.getJSON()).toEqual(
      doc(
        p(time({ title: 'November 2, 2023', datetime: '2023-11-02' }, 'November 2, 2023')),
      ).toJSON(),
    );
  });
});
