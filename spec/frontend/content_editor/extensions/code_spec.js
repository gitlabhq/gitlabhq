import { builders } from 'prosemirror-test-builder';
import Bold from '~/content_editor/extensions/bold';
import Code from '~/content_editor/extensions/code';
import { createTestEditor } from '../test_utils';

const CODE_HTML = `<p dir="auto" data-sourcepos="1:1-1:31"><code data-sourcepos="1:2-1:30">     code with leading spaces</code></p>`;

describe('content_editor/extensions/code', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let code;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Bold, Code] });

    ({ doc, paragraph: p, bold, code } = builders(tiptapEditor.schema));
  });

  it.each`
    markOrder           | description
    ${['bold', 'code']} | ${'bold is toggled before code'}
    ${['code', 'bold']} | ${'code is toggled before bold'}
  `('has a lower loading priority, when $description', ({ markOrder }) => {
    const initialDoc = doc(p('code block'));
    const expectedDoc = doc(p(bold(code('code block'))));

    tiptapEditor.commands.setContent(initialDoc.toJSON());
    tiptapEditor.commands.selectAll();
    markOrder.forEach((mark) => tiptapEditor.commands.toggleMark(mark));

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });

  describe('when parsing HTML', () => {
    beforeEach(() => {
      tiptapEditor.commands.setContent(CODE_HTML);
    });

    it('parses HTML correctly into an inline code block, preserving leading spaces', () => {
      expect(tiptapEditor.getJSON()).toEqual(
        doc(p(code('     code with leading spaces'))).toJSON(),
      );
    });
  });

  describe('shortcut: RightArrow', () => {
    it('exits the code block', () => {
      const initialDoc = doc(p('You can write ', code('java')));
      const expectedDoc = doc(p('You can write ', code('javascript'), ' here'));
      const pos = 25;

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(pos);

      // insert 'script' after 'java' within the code block
      tiptapEditor.commands.insertContent({ type: 'text', text: 'script' });

      // insert ' here' after the code block
      tiptapEditor.commands.keyboardShortcut('ArrowRight');
      tiptapEditor.commands.insertContent({ type: 'text', text: 'here' });

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
