import MockAdapter from 'axios-mock-adapter';
import { Range, Position } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { EXTENSION_MARKDOWN_BUTTONS } from '~/editor/constants';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';
import axios from '~/lib/utils/axios_utils';

describe('Markdown Extension for Source Editor', () => {
  let editor;
  let instance;
  let editorEl;
  let mockAxios;
  const firstLine = 'This is a';
  const secondLine = 'multiline';
  const thirdLine = 'string with some **markup**';
  const text = `${firstLine}\n${secondLine}\n${thirdLine}`;
  const markdownPath = 'foo.md';
  let extensions;

  // eslint-disable-next-line max-params
  const setSelection = (startLineNumber = 1, startColumn = 1, endLineNumber = 1, endColumn = 1) => {
    const selection = new Range(startLineNumber, startColumn, endLineNumber, endColumn);
    instance.setSelection(selection);
  };
  const selectSecondString = () => setSelection(2, 1, 2, secondLine.length + 1); // select the whole second line
  const selectSecondAndThirdLines = () => setSelection(2, 1, 3, thirdLine.length + 1); // select second and third lines

  const selectionToString = () => instance.getSelection().toString();
  const positionToString = () => instance.getPosition().toString();

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    setHTMLFixture('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({
      el: editorEl,
      blobPath: markdownPath,
      blobContent: text,
    });
    extensions = instance.use([
      { definition: ToolbarExtension },
      { definition: EditorMarkdownExtension },
    ]);
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
    mockAxios.restore();

    resetHTMLFixture();
  });

  describe('toolbar', () => {
    it('renders all the buttons', () => {
      const btns = instance.toolbar.getAllItems();
      expect(btns).toHaveLength(EXTENSION_MARKDOWN_BUTTONS.length);
      EXTENSION_MARKDOWN_BUTTONS.forEach((btn, i) => {
        expect(btns[i].id).toBe(btn.id);
      });
    });
  });

  describe('markdown keystrokes', () => {
    it('registers all keystrokes as actions', () => {
      EXTENSION_MARKDOWN_BUTTONS.forEach((button) => {
        if (button.data.mdShortcuts) {
          expect(instance.getAction(button.id)).toBeDefined();
        }
      });
    });

    it('disposes all keystrokes on unuse', () => {
      instance.unuse(extensions[1]);
      EXTENSION_MARKDOWN_BUTTONS.forEach((button) => {
        if (button.data.mdShortcuts) {
          expect(instance.getAction(button.id)).toBeNull();
        }
      });
    });
  });

  describe('getSelectedText', () => {
    it('does not fail if there is no selection and returns the empty string', () => {
      jest.spyOn(instance, 'getSelection');
      const resText = instance.getSelectedText();

      expect(instance.getSelection).toHaveBeenCalled();
      expect(resText).toBe('');
    });

    it.each`
      description      | selection                           | expectedString
      ${'same-line'}   | ${[1, 1, 1, firstLine.length + 1]}  | ${firstLine}
      ${'two-lines'}   | ${[1, 1, 2, secondLine.length + 1]} | ${`${firstLine}\n${secondLine}`}
      ${'multi-lines'} | ${[1, 1, 3, thirdLine.length + 1]}  | ${text}
    `('correctly returns selected text for $description', ({ selection, expectedString }) => {
      setSelection(...selection);

      const resText = instance.getSelectedText();

      expect(resText).toBe(expectedString);
    });

    it('accepts selection object that serves as a source instead of current selection', () => {
      selectSecondString();
      const firstLineSelection = new Range(1, 1, 1, firstLine.length + 1);

      const resText = instance.getSelectedText(firstLineSelection);

      expect(resText).toBe(firstLine);
    });
  });

  describe('replaceSelectedText', () => {
    const expectedStr = 'foo';

    it('replaces selected text with the supplied one', () => {
      selectSecondString();
      instance.replaceSelectedText(expectedStr);

      expect(instance.getValue()).toBe(`${firstLine}\n${expectedStr}\n${thirdLine}`);
    });

    it('prepends the supplied text if no text is selected', () => {
      instance.replaceSelectedText(expectedStr);
      expect(instance.getValue()).toBe(`${expectedStr}${firstLine}\n${secondLine}\n${thirdLine}`);
    });

    it('replaces selection with empty string if no text is supplied', () => {
      selectSecondString();
      instance.replaceSelectedText();
      expect(instance.getValue()).toBe(`${firstLine}\n\n${thirdLine}`);
    });

    it('puts cursor at the end of the new string and collapses selection by default', () => {
      selectSecondString();
      instance.replaceSelectedText(expectedStr);

      expect(positionToString()).toBe(`(2,${expectedStr.length + 1})`);
      expect(selectionToString()).toBe(
        `[2,${expectedStr.length + 1} -> 2,${expectedStr.length + 1}]`,
      );
    });

    it('puts cursor at the end of the new string and keeps selection if "select" is supplied', () => {
      const select = 'url';
      const complexReplacementString = `[${secondLine}](${select})`;
      selectSecondString();
      instance.replaceSelectedText(complexReplacementString, select);

      expect(positionToString()).toBe(`(2,${complexReplacementString.length + 1})`);
      expect(selectionToString()).toBe(`[2,1 -> 2,${complexReplacementString.length + 1}]`);
    });
  });

  describe('moveCursor', () => {
    const setPosition = (endCol) => {
      const currentPos = new Position(2, endCol);
      instance.setPosition(currentPos);
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
          instance.moveCursor(...shift);
        } else {
          instance.moveCursor(shift);
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

      instance.selectWithinSelection(toSelect, selectedText);
      expect(selectionToString()).toBe(`[3,1 -> 3,${toSelect.length + 1}]`);
    });

    it('does not fail when only `toSelect` is supplied and fetches the text from selection', () => {
      const toSelect = 'string';
      selectSecondAndThirdLines();

      instance.selectWithinSelection(toSelect);

      expect(selectionToString()).toBe(`[3,1 -> 3,${toSelect.length + 1}]`);
    });

    it('does nothing if no `toSelect` is supplied', () => {
      selectSecondAndThirdLines();
      const expectedPos = `(3,${thirdLine.length + 1})`;
      const expectedSelection = `[2,1 -> 3,${thirdLine.length + 1}]`;

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      instance.selectWithinSelection();

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);
    });

    it('does nothing if no selection is set in the editor', () => {
      const expectedPos = '(1,1)';
      const expectedSelection = '[1,1 -> 1,1]';
      const toSelect = 'string';

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      instance.selectWithinSelection(toSelect);

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);

      instance.selectWithinSelection();

      expect(positionToString()).toBe(expectedPos);
      expect(selectionToString()).toBe(expectedSelection);
    });
  });
});
