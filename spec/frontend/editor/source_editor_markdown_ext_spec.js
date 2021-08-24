import MockAdapter from 'axios-mock-adapter';
import { Range, Position, editor as monacoEditor } from 'monaco-editor';
import waitForPromises from 'helpers/wait_for_promises';
import {
  EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
} from '~/editor/constants';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import SourceEditor from '~/editor/source_editor';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import syntaxHighlight from '~/syntax_highlight';

jest.mock('~/syntax_highlight');
jest.mock('~/flash');

describe('Markdown Extension for Source Editor', () => {
  let editor;
  let instance;
  let editorEl;
  let panelSpy;
  let mockAxios;
  const previewMarkdownPath = '/gitlab/fooGroup/barProj/preview_markdown';
  const firstLine = 'This is a';
  const secondLine = 'multiline';
  const thirdLine = 'string with some **markup**';
  const text = `${firstLine}\n${secondLine}\n${thirdLine}`;
  const plaintextPath = 'foo.txt';
  const markdownPath = 'foo.md';
  const responseData = '<div>FooBar</div>';

  const setSelection = (startLineNumber = 1, startColumn = 1, endLineNumber = 1, endColumn = 1) => {
    const selection = new Range(startLineNumber, startColumn, endLineNumber, endColumn);
    instance.setSelection(selection);
  };
  const selectSecondString = () => setSelection(2, 1, 2, secondLine.length + 1); // select the whole second line
  const selectSecondAndThirdLines = () => setSelection(2, 1, 3, thirdLine.length + 1); // select second and third lines

  const selectionToString = () => instance.getSelection().toString();
  const positionToString = () => instance.getPosition().toString();

  const togglePreview = async () => {
    instance.togglePreview();
    await waitForPromises();
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({
      el: editorEl,
      blobPath: markdownPath,
      blobContent: text,
    });
    editor.use(new EditorMarkdownExtension({ instance, previewMarkdownPath }));
    panelSpy = jest.spyOn(EditorMarkdownExtension, 'togglePreviewPanel');
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
    mockAxios.restore();
  });

  it('sets up the instance', () => {
    expect(instance.preview).toEqual({
      el: undefined,
      action: expect.any(Object),
      shown: false,
      modelChangeListener: undefined,
    });
    expect(instance.previewMarkdownPath).toBe(previewMarkdownPath);
  });

  describe('model language changes listener', () => {
    let cleanupSpy;
    let actionSpy;

    beforeEach(async () => {
      cleanupSpy = jest.spyOn(instance, 'cleanup');
      actionSpy = jest.spyOn(instance, 'setupPreviewAction');
      await togglePreview();
    });

    it('cleans up when switching away from markdown', () => {
      expect(instance.cleanup).not.toHaveBeenCalled();
      expect(instance.setupPreviewAction).not.toHaveBeenCalled();

      instance.updateModelLanguage(plaintextPath);

      expect(cleanupSpy).toHaveBeenCalled();
      expect(actionSpy).not.toHaveBeenCalled();
    });

    it.each`
      oldLanguage    | newLanguage    | setupCalledTimes
      ${'plaintext'} | ${'markdown'}  | ${1}
      ${'markdown'}  | ${'markdown'}  | ${0}
      ${'markdown'}  | ${'plaintext'} | ${0}
      ${'markdown'}  | ${undefined}   | ${0}
      ${undefined}   | ${'markdown'}  | ${1}
    `(
      'correctly handles re-enabling of the action when switching from $oldLanguage to $newLanguage',
      ({ oldLanguage, newLanguage, setupCalledTimes } = {}) => {
        expect(actionSpy).not.toHaveBeenCalled();
        instance.updateModelLanguage(oldLanguage);
        instance.updateModelLanguage(newLanguage);
        expect(actionSpy).toHaveBeenCalledTimes(setupCalledTimes);
      },
    );
  });

  describe('model change listener', () => {
    let cleanupSpy;
    let actionSpy;

    beforeEach(() => {
      cleanupSpy = jest.spyOn(instance, 'cleanup');
      actionSpy = jest.spyOn(instance, 'setupPreviewAction');
      instance.togglePreview();
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('does not do anything if there is no model', () => {
      instance.setModel(null);

      expect(cleanupSpy).not.toHaveBeenCalled();
      expect(actionSpy).not.toHaveBeenCalled();
    });

    it('cleans up the preview when the model changes', () => {
      instance.setModel(monacoEditor.createModel('foo'));
      expect(cleanupSpy).toHaveBeenCalled();
    });

    it.each`
      language       | setupCalledTimes
      ${'markdown'}  | ${1}
      ${'plaintext'} | ${0}
      ${undefined}   | ${0}
    `(
      'correctly handles actions when the new model is $language',
      ({ language, setupCalledTimes } = {}) => {
        instance.setModel(monacoEditor.createModel('foo', language));

        expect(actionSpy).toHaveBeenCalledTimes(setupCalledTimes);
      },
    );
  });

  describe('cleanup', () => {
    beforeEach(async () => {
      mockAxios.onPost().reply(200, { body: responseData });
      await togglePreview();
    });

    it('disposes the modelChange listener and does not fetch preview on content changes', () => {
      expect(instance.preview.modelChangeListener).toBeDefined();
      jest.spyOn(instance, 'fetchPreview');

      instance.cleanup();
      instance.setValue('Foo Bar');
      jest.advanceTimersByTime(EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY);

      expect(instance.fetchPreview).not.toHaveBeenCalled();
    });

    it('removes the contextual menu action', () => {
      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBeDefined();

      instance.cleanup();

      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBe(null);
    });

    it('toggles the `shown` flag', () => {
      expect(instance.preview.shown).toBe(true);
      instance.cleanup();
      expect(instance.preview.shown).toBe(false);
    });

    it('toggles the panel only if the preview is visible', () => {
      const { el: previewEl } = instance.preview;
      const parentEl = previewEl.parentElement;

      expect(previewEl).toBeVisible();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(true);

      instance.cleanup();
      expect(previewEl).toBeHidden();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
        false,
      );

      instance.cleanup();
      expect(previewEl).toBeHidden();
      expect(parentEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
        false,
      );
    });

    it('toggles the layout only if the preview is visible', () => {
      const { width } = instance.getLayoutInfo();

      expect(instance.preview.shown).toBe(true);

      instance.cleanup();

      const { width: newWidth } = instance.getLayoutInfo();
      expect(newWidth === width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH).toBe(true);

      instance.cleanup();
      expect(newWidth === width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH).toBe(true);
    });
  });

  describe('fetchPreview', () => {
    const fetchPreview = async () => {
      instance.fetchPreview();
      await waitForPromises();
    };

    let previewMarkdownSpy;

    beforeEach(() => {
      previewMarkdownSpy = jest.fn().mockImplementation(() => [200, { body: responseData }]);
      mockAxios.onPost(previewMarkdownPath).replyOnce((req) => previewMarkdownSpy(req));
    });

    it('correctly fetches preview based on previewMarkdownPath', async () => {
      await fetchPreview();

      expect(previewMarkdownSpy).toHaveBeenCalledWith(
        expect.objectContaining({ data: JSON.stringify({ text }) }),
      );
    });

    it('puts the fetched content into the preview DOM element', async () => {
      instance.preview.el = editorEl.parentElement;
      await fetchPreview();
      expect(instance.preview.el.innerHTML).toEqual(responseData);
    });

    it('applies syntax highlighting to the preview content', async () => {
      instance.preview.el = editorEl.parentElement;
      await fetchPreview();
      expect(syntaxHighlight).toHaveBeenCalled();
    });

    it('catches the errors when fetching the preview', async () => {
      mockAxios.onPost().reply(500);

      await fetchPreview();
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('setupPreviewAction', () => {
    it('adds the contextual menu action', () => {
      expect(instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)).toBeDefined();
    });

    it('does not set up action if one already exists', () => {
      jest.spyOn(instance, 'addAction').mockImplementation();

      instance.setupPreviewAction();
      expect(instance.addAction).not.toHaveBeenCalled();
    });

    it('toggles preview when the action is triggered', () => {
      jest.spyOn(instance, 'togglePreview').mockImplementation();

      expect(instance.togglePreview).not.toHaveBeenCalled();

      const action = instance.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID);
      action.run();

      expect(instance.togglePreview).toHaveBeenCalled();
    });
  });

  describe('togglePreview', () => {
    beforeEach(() => {
      mockAxios.onPost().reply(200, { body: responseData });
    });

    it('toggles preview flag on instance', () => {
      expect(instance.preview.shown).toBe(false);

      instance.togglePreview();
      expect(instance.preview.shown).toBe(true);

      instance.togglePreview();
      expect(instance.preview.shown).toBe(false);
    });

    describe('panel DOM element set up', () => {
      it('sets up an element to contain the preview and stores it on instance', () => {
        expect(instance.preview.el).toBeUndefined();

        instance.togglePreview();

        expect(instance.preview.el).toBeDefined();
        expect(instance.preview.el.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS)).toBe(
          true,
        );
      });

      it('re-uses existing preview DOM element on repeated calls', () => {
        instance.togglePreview();
        const origPreviewEl = instance.preview.el;
        instance.togglePreview();

        expect(instance.preview.el).toBe(origPreviewEl);
      });

      it('hides the preview DOM element by default', () => {
        panelSpy.mockImplementation();
        instance.togglePreview();
        expect(instance.preview.el.style.display).toBe('none');
      });
    });

    describe('preview layout setup', () => {
      it('sets correct preview layout', () => {
        jest.spyOn(instance, 'layout');
        const { width, height } = instance.getLayoutInfo();

        instance.togglePreview();

        expect(instance.layout).toHaveBeenCalledWith({
          width: width * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
          height,
        });
      });
    });

    describe('preview panel', () => {
      it('toggles preview CSS class on the editor', () => {
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          false,
        );
        instance.togglePreview();
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          true,
        );
        instance.togglePreview();
        expect(editorEl.classList.contains(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS)).toBe(
          false,
        );
      });

      it('toggles visibility of the preview DOM element', async () => {
        await togglePreview();
        expect(instance.preview.el.style.display).toBe('block');
        await togglePreview();
        expect(instance.preview.el.style.display).toBe('none');
      });

      describe('hidden preview DOM element', () => {
        it('listens to model changes and re-fetches preview', async () => {
          expect(mockAxios.history.post).toHaveLength(0);
          await togglePreview();
          expect(mockAxios.history.post).toHaveLength(1);

          instance.setValue('New Value');
          await waitForPromises();
          expect(mockAxios.history.post).toHaveLength(2);
        });

        it('stores disposable listener for model changes', async () => {
          expect(instance.preview.modelChangeListener).toBeUndefined();
          await togglePreview();
          expect(instance.preview.modelChangeListener).toBeDefined();
        });
      });

      describe('already visible preview', () => {
        beforeEach(async () => {
          await togglePreview();
          mockAxios.resetHistory();
        });

        it('does not re-fetch the preview', () => {
          instance.togglePreview();
          expect(mockAxios.history.post).toHaveLength(0);
        });

        it('disposes the model change event listener', () => {
          const disposeSpy = jest.fn();
          instance.preview.modelChangeListener = {
            dispose: disposeSpy,
          };
          instance.togglePreview();
          expect(disposeSpy).toHaveBeenCalled();
        });
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
      jest.spyOn(instance, 'getSelectedText');
      const toSelect = 'string';
      selectSecondAndThirdLines();

      instance.selectWithinSelection(toSelect);

      expect(instance.getSelectedText).toHaveBeenCalled();
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
