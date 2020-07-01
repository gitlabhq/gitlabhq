import EditorLite from '~/editor/editor_lite';
import { Range, Position } from 'monaco-editor';
import EditorMarkdownExtension from '~/editor/editor_markdown_ext';

describe('Markdown Extension for Editor Lite', () => {
  let editor;
  let editorEl;
  const firstLine = 'This is a';
  const secondLine = 'multiline';
  const thirdLine = 'string with some **markup**';
  const text = `${firstLine}\n${secondLine}\n${thirdLine}`;
  const filePath = 'foo.md';

  const setSelection = (startLineNumber = 1, startColumn = 1, endLineNumber = 1, endColumn = 1) => {
    const selection = new Range(startLineNumber, startColumn, endLineNumber, endColumn);
    editor.instance.setSelection(selection);
  };
  const selectSecondString = () => setSelection(2, 1, 2, secondLine.length + 1); // select the whole second line
  const selectSecondAndThirdLines = () => setSelection(2, 1, 3, thirdLine.length + 1); // select second and third lines

  const selectionToString = () => editor.instance.getSelection().toString();
  const positionToString = () => editor.instance.getPosition().toString();

  beforeEach(() => {
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new EditorLite();
    editor.createInstance({
      el: editorEl,
      blobPath: filePath,
      blobContent: text,
    });
    editor.use(EditorMarkdownExtension);
  });

  afterEach(() => {
    editor.instance.dispose();
    editor.model.dispose();
    editorEl.remove();
  });

  describe('getSelectedText', () => {
    it('does not fail if there is no selection and returns the empty string', () => {
      jest.spyOn(editor.instance, 'getSelection');
      const resText = editor.getSelectedText();

      expect(editor.instance.getSelection).toHaveBeenCalled();
      expect(resText).toBe('');
    });

    it.each`
      description      | selection                           | expectedString
      ${'same-line'}   | ${[1, 1, 1, firstLine.length + 1]}  | ${firstLine}
      ${'two-lines'}   | ${[1, 1, 2, secondLine.length + 1]} | ${`${firstLine}\n${secondLine}`}
      ${'multi-lines'} | ${[1, 1, 3, thirdLine.length + 1]}  | ${text}
    `('correctly returns selected text for $description', ({ selection, expectedString }) => {
      setSelection(...selection);

      const resText = editor.getSelectedText();

      expect(resText).toBe(expectedString);
    });

    it('accepts selection object that serves as a source instead of current selection', () => {
      selectSecondString();
      const firstLineSelection = new Range(1, 1, 1, firstLine.length + 1);

      const resText = editor.getSelectedText(firstLineSelection);

      expect(resText).toBe(firstLine);
    });
  });

  describe('replaceSelectedText', () => {
    const expectedStr = 'foo';

    it('replaces selected text with the supplied one', () => {
      selectSecondString();
      editor.replaceSelectedText(expectedStr);

      expect(editor.getValue()).toBe(`${firstLine}\n${expectedStr}\n${thirdLine}`);
    });

    it('prepends the supplied text if no text is selected', () => {
      editor.replaceSelectedText(expectedStr);
      expect(editor.getValue()).toBe(`${expectedStr}${firstLine}\n${secondLine}\n${thirdLine}`);
    });

    it('replaces selection with empty string if no text is supplied', () => {
      selectSecondString();
      editor.replaceSelectedText();
      expect(editor.getValue()).toBe(`${firstLine}\n\n${thirdLine}`);
    });

    it('puts cursor at the end of the new string and collapses selection by default', () => {
      selectSecondString();
      editor.replaceSelectedText(expectedStr);

      expect(positionToString()).toBe(`(2,${expectedStr.length + 1})`);
      expect(selectionToString()).toBe(
        `[2,${expectedStr.length + 1} -> 2,${expectedStr.length + 1}]`,
      );
    });

    it('puts cursor at the end of the new string and keeps selection if "select" is supplied', () => {
      const select = 'url';
      const complexReplacementString = `[${secondLine}](${select})`;
      selectSecondString();
      editor.replaceSelectedText(complexReplacementString, select);

      expect(positionToString()).toBe(`(2,${complexReplacementString.length + 1})`);
      expect(selectionToString()).toBe(`[2,1 -> 2,${complexReplacementString.length + 1}]`);
    });
  });

  describe('moveCursor', () => {
    const setPosition = endCol => {
      const currentPos = new Position(2, endCol);
      editor.instance.setPosition(currentPos);
    };

    it.each`
      direction          | condition      | startColumn              | shift                      | endPosition
      ${'left'}          | ${'negative'}  | ${secondLine.length + 1} | ${-1}                      | ${`(2,${secondLine.length})`}
      ${'left'}          | ${'negative'}  | ${secondLine.length}     | ${secondLine.length * -1}  | ${'(2,1)'}
      ${'right'}         | ${'positive'}  | ${1}                     | ${1}                       | ${'(2,2)'}
      ${'right'}         | ${'positive'}  | ${2}                     | ${secondLine.length}       | ${`(2,${secondLine.length + 1})`}
      ${'up'}            | ${'positive'}  | ${1}                     | ${[0, -1]}                 | ${'(1,1)'}
      ${'top of file'}   | ${'positive'}  | ${1}                     | ${[0, -100]}               | ${'(1,1)'}
      ${'down'}          | ${'negative'}  | ${1}                     | ${[0, 1]}                  | ${'(3,1)'}
      ${'end of file'}   | ${'negative'}  | ${1}                     | ${[0, 100]}                | ${`(3,${thirdLine.length + 1})`}
      ${'end of line'}   | ${'too large'} | ${1}                     | ${secondLine.length + 100} | ${`(2,${secondLine.length + 1})`}
      ${'start of line'} | ${'too low'}   | ${1}                     | ${-100}                    | ${'(2,1)'}
    `(
      'moves cursor to the $direction if $condition supplied',
      ({ startColumn, shift, endPosition }) => {
        setPosition(startColumn);
        if (Array.isArray(shift)) {
          editor.moveCursor(...shift);
        } else {
          editor.moveCursor(shift);
        }
        expect(positionToString()).toBe(endPosition);
      },
    );
  });

  describe('selectWithinSelection', () => {
    it('scopes down current selection to supplied text', () => {
      const selectedText = `${secondLine}\n${thirdLine}`;
      const toSelect = 'string';
      selectSecondAndThirdLines();

      expect(selectionToString()).toBe(`[2,1 -> 3,${thirdLine.length + 1}]`);

      editor.selectWithinSelection(toSelect, selectedText);
      expect(selectionToString()).toBe(`[3,1 -> 3,${toSelect.length + 1}]`);
    });

    it('does not fail when only `toSelect` is supplied and fetches the text from selection', () => {
      jest.spyOn(editor, 'getSelectedText');
      const toSelect = 'string';
      selectSecondAndThirdLines();

      editor.selectWithinSelection(toSelect);

      expect(editor.getSelectedText).toHaveBeenCalled();
      expect(selectionToString()).toBe(`[3,1 -> 3,${toSelect.length + 1}]`);
    });

    it('does nothing if no `toSelect` is supplied', () => {
      selectSecondAndThirdLines();
      const expectedPos = `(3,${thirdLine.length + 1})`;
      const expectedSelection = `[2,1 -> 3,${thirdLine.length + 1}]`;

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      editor.selectWithinSelection();

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);
    });

    it('does nothing if no selection is set in the editor', () => {
      const expectedPos = '(1,1)';
      const expectedSelection = '[1,1 -> 1,1]';
      const toSelect = 'string';

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      editor.selectWithinSelection(toSelect);

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      editor.selectWithinSelection();

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);
    });
  });
});
