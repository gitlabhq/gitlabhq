import { builders } from 'prosemirror-test-builder';
import Indent, { INDENT_SPACES } from '~/content_editor/extensions/indent';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import { createTestEditor, triggerKeyboardInput } from '../test_utils';

describe('content_editor/extensions/indent', () => {
  let tiptapEditor;
  let codeBlock;
  let doc;
  let p;

  const indentation = INDENT_SPACES;

  const setRegularText = (text, cursorPos = 0) => {
    tiptapEditor.commands.insertContent({
      type: 'paragraph',
      content: [{ type: 'text', text }],
    });

    tiptapEditor.commands.setTextSelection(cursorPos);
  };

  const setCodeBlock = (text, cursorPos = 0) => {
    tiptapEditor.commands.insertContent({
      type: 'codeBlock',
      attrs: { language: 'ruby' },
      content: [{ type: 'text', text }],
    });

    tiptapEditor.commands.setTextSelection(cursorPos);
  };

  const expectedDoc = (text) =>
    doc(codeBlock({ language: 'ruby', class: 'code highlight' }, text)).toJSON();

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Indent, CodeBlockHighlight] });

    ({ codeBlock, doc, paragraph: p } = builders(tiptapEditor.schema));
  });

  const text = 'example text.';

  describe('indent', () => {
    const lineContentAfterTab = (tabs = 1) => {
      Array.from({ length: tabs }).forEach(() => {
        triggerKeyboardInput({ tiptapEditor, key: 'Tab' });
      });

      return tiptapEditor.state.doc.toJSON();
    };

    it('should not indent when the content is not in a codeBlock', () => {
      setRegularText(text, 0);

      tiptapEditor.commands.setTextSelection(0);
      expect(lineContentAfterTab()).toEqual(doc(p({}, text)).toJSON());
    });

    it.each`
      input   | result                           | cursorPos | tabs
      ${' '}  | ${`${indentation} `}             | ${0}      | ${1}
      ${text} | ${indentation.repeat(2) + text}  | ${0}      | ${2}
      ${text} | ${`exa${indentation}mple text.`} | ${4}      | ${1}
      ${text} | ${text + indentation.repeat(3)}  | ${14}     | ${3}
    `('should insert indentation wherever the cursor is', ({ input, result, cursorPos, tabs }) => {
      setCodeBlock(input, cursorPos);
      expect(lineContentAfterTab(tabs)).toEqual(expectedDoc(result));
    });

    describe('when text is selected', () => {
      it('should insert indentation in front of the entire text on that line', () => {
        setCodeBlock(text);
        expect(lineContentAfterTab()).toEqual(expectedDoc(`${indentation}example text.`));
      });

      it.each`
        input                                          | result                                                                                           | cursorPos              | tabs
        ${`${text}`}                                   | ${`${indentation.repeat(6)}${text}`}                                                             | ${{ from: 3, to: 10 }} | ${6}
        ${`${text}\n${text}`}                          | ${`${indentation}${text}\n${indentation}${text}`}                                                | ${{ from: 0, to: 24 }} | ${1}
        ${`${text}\n${' '.repeat(3)}${text}\n${text}`} | ${`${indentation.repeat(10)}${text}\n${indentation.repeat(10)}${' '.repeat(3)}${text}\n${text}`} | ${{ from: 0, to: 27 }} | ${10}
      `(
        'indent correctly when text is highlighted and set selection correctly',
        ({ input, result, cursorPos, tabs }) => {
          setCodeBlock(input, cursorPos);
          expect(lineContentAfterTab(tabs)).toEqual(expectedDoc(result));
        },
      );
    });
  });

  describe('outdent', () => {
    const lineContentAfterShiftTab = (tabs = 1) => {
      Array.from({ length: tabs }).forEach(() => {
        triggerKeyboardInput({ tiptapEditor, key: 'Tab', shiftKey: true });
      });

      return tiptapEditor.state.doc.toJSON();
    };

    it('should not outdent when the content is not in a codeBlock', () => {
      const input = `${' '.repeat(2)}${text}`;
      setRegularText(input, 0);

      tiptapEditor.commands.setTextSelection(0);
      expect(lineContentAfterShiftTab()).toEqual(doc(p({}, input)).toJSON());
    });

    it('should never shift text into the previous line', () => {
      const input = `first line \nsecond line`;

      const secondLinePos = tiptapEditor.getText().indexOf('\n') + 1;

      setCodeBlock(input, secondLinePos);
      expect(lineContentAfterShiftTab(20)).toEqual(expectedDoc(input));
    });

    describe('basic outdent functionality', () => {
      it.each`
        input                   | result
        ${' '.repeat(8)}        | ${' '.repeat(6)}
        ${' '.repeat(1)}        | ${''}
        ${text}                 | ${text}
        ${' '.repeat(4) + text} | ${' '.repeat(2) + text}
        ${' '.repeat(2) + text} | ${text}
      `('should outdent correctly when the whitespace is after the cursor', ({ input, result }) => {
        setCodeBlock(input);
        expect(lineContentAfterShiftTab()).toEqual(expectedDoc(result));
      });

      it.each`
        input                                 | result                  | cursorPos
        ${' '.repeat(8)}                      | ${' '.repeat(6)}        | ${9}
        ${' '.repeat(1)}                      | ${''}                   | ${3}
        ${text}                               | ${text}                 | ${11}
        ${' '.repeat(4) + text}               | ${' '.repeat(2) + text} | ${5}
        ${' '.repeat(2) + text}               | ${text}                 | ${3}
        ${`${text}\n${' '.repeat(2)}${text}`} | ${`${text}\n${text}`}   | ${17}
      `(
        'should outdent correctly when the whitespace is before the cursor',
        ({ input, result, cursorPos }) => {
          setCodeBlock(input, cursorPos);
          expect(lineContentAfterShiftTab()).toEqual(expectedDoc(result));
        },
      );

      it.each`
        input                                   | result                  | cursorPos | tabs
        ${text}                                 | ${text}                 | ${13}     | ${1}
        ${' '.repeat(4) + text}                 | ${text}                 | ${18}     | ${3}
        ${' '.repeat(2) + text}                 | ${text}                 | ${14}     | ${2}
        ${' '.repeat(2) + text}                 | ${text}                 | ${10}     | ${1}
        ${`${text}\n${' '.repeat(2)}${text}`}   | ${`${text}\n${text}`}   | ${25}     | ${1}
        ${`${text}\n\n${' '.repeat(1)}${text}`} | ${`${text}\n\n${text}`} | ${25}     | ${10}
      `(
        'should outdent correctly when the cursor is somewhere in the text',
        ({ input, result, cursorPos, tabs }) => {
          setCodeBlock(input, cursorPos);
          expect(lineContentAfterShiftTab(tabs)).toEqual(expectedDoc(result));
        },
      );

      it.each`
        input                                                                 | result                                               | cursorPos              | tabs
        ${`${text}\n${text}`}                                                 | ${`${text}\n${text}`}                                | ${{ from: 7, to: 25 }} | ${1}
        ${`${' '.repeat(4)}${text}\n \n ${text}`}                             | ${`${' '.repeat(2)}${text}\n\n${text}`}              | ${{ from: 2, to: 28 }} | ${1}
        ${`${' '.repeat(2)}\n${text}`}                                        | ${`\n${text}`}                                       | ${{ from: 1, to: 11 }} | ${1}
        ${`${' '.repeat(8)}${text}${' '}\n${' '.repeat(4)}${text}\n${text}`}  | ${`${' '.repeat(2)}${text}${' '}\n${text}\n${text}`} | ${{ from: 9, to: 45 }} | ${3}
        ${`${' '.repeat(5)}${text}\n${' '}${text}`}                           | ${`${' '.repeat(3)}${text}\n${text}`}                | ${{ from: 3, to: 25 }} | ${1}
        ${`${text}\n${' '.repeat(10)}${text}${' '}`}                          | ${`${text}\n${' '.repeat(4)}${text}${' '}`}          | ${{ from: 3, to: 25 }} | ${3}
        ${`${' '.repeat(10)}${text}\n${' '.repeat(6)}${text}\n${' '}${text}`} | ${`${text}\n${text}\n${' '}${text}`}                 | ${{ from: 0, to: 40 }} | ${15}
      `(
        'should outdent correctly when the selection spans multiple lines',
        ({ input, result, cursorPos, tabs }) => {
          setCodeBlock(input, cursorPos);
          expect(lineContentAfterShiftTab(tabs)).toEqual(expectedDoc(result));
        },
      );
    });

    describe('outdentation precedence', () => {
      // the correct outdentation precedence is
      // 1. The whitespace after the cursor
      // 2. The whitespace before the cursor
      // 3. The whitespace before the first character

      it('should outdent with the correct precedence', () => {
        const content = ' '.repeat(6) + text;
        setCodeBlock(content);

        // should remove the white space after the cursor
        tiptapEditor.commands.setTextSelection(3);
        expect(lineContentAfterShiftTab()).toEqual(expectedDoc(' '.repeat(4) + text));

        // should remove 2 of the 4 whitespaces before the cursor
        tiptapEditor.commands.setTextSelection(3);
        expect(lineContentAfterShiftTab()).toEqual(expectedDoc(' '.repeat(2) + text));

        // should move the cursor to the end of the remaining text, then remove the remaining whitespace from in front of the first text
        tiptapEditor.commands.setTextSelection(15);
        expect(lineContentAfterShiftTab()).toEqual(expectedDoc(text));
      });
    });
  });
});
