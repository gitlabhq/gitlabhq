import Bold from '~/content_editor/extensions/bold';
import Code from '~/content_editor/extensions/code';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/code', () => {
  let tiptapEditor;
  let doc;
  let p;
  let bold;
  let code;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Bold, Code] });

    ({
      builders: { doc, p, bold, code },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        bold: { markType: Bold.name },
        code: { markType: Code.name },
      },
    }));
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
