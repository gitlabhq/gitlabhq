import { debounce } from 'lodash';
import { BLOB_PREVIEW_ERROR } from '~/blob_edit/constants';
import createFlash from '~/flash';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import syntaxHighlight from '~/syntax_highlight';
import {
  EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH,
  EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS,
  EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY,
} from '../constants';
import { SourceEditorExtension } from './source_editor_extension_base';

const getPreview = (text, previewMarkdownPath) => {
  return axios
    .post(previewMarkdownPath, {
      text,
    })
    .then(({ data }) => {
      return data.body;
    });
};

const setupDomElement = ({ injectToEl = null } = {}) => {
  const previewEl = document.createElement('div');
  previewEl.classList.add(EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS);
  previewEl.style.display = 'none';
  if (injectToEl) {
    injectToEl.appendChild(previewEl);
  }
  return previewEl;
};

export class EditorMarkdownExtension extends SourceEditorExtension {
  constructor({ instance, previewMarkdownPath, ...args } = {}) {
    super({ instance, ...args });
    Object.assign(instance, {
      previewMarkdownPath,
      preview: {
        el: undefined,
        action: undefined,
        shown: false,
        modelChangeListener: undefined,
      },
    });
    this.setupPreviewAction.call(instance);

    instance.getModel().onDidChangeLanguage(({ newLanguage, oldLanguage } = {}) => {
      if (newLanguage === 'markdown' && oldLanguage !== newLanguage) {
        instance.setupPreviewAction();
      } else {
        instance.cleanup();
      }
    });

    instance.onDidChangeModel(() => {
      const model = instance.getModel();
      if (model) {
        const { language } = model.getLanguageIdentifier();
        instance.cleanup();
        if (language === 'markdown') {
          instance.setupPreviewAction();
        }
      }
    });
  }

  static togglePreviewLayout() {
    const { width, height } = this.getLayoutInfo();
    const newWidth = this.preview.shown
      ? width / EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH
      : width * EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH;
    this.layout({ width: newWidth, height });
  }

  static togglePreviewPanel() {
    const parentEl = this.getDomNode().parentElement;
    const { el: previewEl } = this.preview;
    parentEl.classList.toggle(EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS);

    if (previewEl.style.display === 'none') {
      // Show the preview panel
      this.fetchPreview();
    } else {
      // Hide the preview panel
      previewEl.style.display = 'none';
    }
  }

  cleanup() {
    if (this.preview.modelChangeListener) {
      this.preview.modelChangeListener.dispose();
    }
    this.preview.action.dispose();
    if (this.preview.shown) {
      EditorMarkdownExtension.togglePreviewPanel.call(this);
      EditorMarkdownExtension.togglePreviewLayout.call(this);
    }
    this.preview.shown = false;
  }

  fetchPreview() {
    const { el: previewEl } = this.preview;
    getPreview(this.getValue(), this.previewMarkdownPath)
      .then((data) => {
        previewEl.innerHTML = sanitize(data);
        syntaxHighlight(previewEl.querySelectorAll('.js-syntax-highlight'));
        previewEl.style.display = 'block';
      })
      .catch(() => createFlash(BLOB_PREVIEW_ERROR));
  }

  setupPreviewAction() {
    if (this.getAction(EXTENSION_MARKDOWN_PREVIEW_ACTION_ID)) return;

    this.preview.action = this.addAction({
      id: EXTENSION_MARKDOWN_PREVIEW_ACTION_ID,
      label: __('Preview Markdown'),
      keybindings: [
        // eslint-disable-next-line no-bitwise,no-undef
        monaco.KeyMod.chord(monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KEY_P),
      ],
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,

      // Method that will be executed when the action is triggered.
      // @param ed The editor instance is passed in as a convenience
      run(instance) {
        instance.togglePreview();
      },
    });
  }

  togglePreview() {
    if (!this.preview?.el) {
      this.preview.el = setupDomElement({ injectToEl: this.getDomNode().parentElement });
    }
    EditorMarkdownExtension.togglePreviewLayout.call(this);
    EditorMarkdownExtension.togglePreviewPanel.call(this);

    if (!this.preview?.shown) {
      this.preview.modelChangeListener = this.onDidChangeModelContent(
        debounce(this.fetchPreview.bind(this), EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY),
      );
    } else {
      this.preview.modelChangeListener.dispose();
    }

    this.preview.shown = !this.preview?.shown;
  }

  getSelectedText(selection = this.getSelection()) {
    const { startLineNumber, endLineNumber, startColumn, endColumn } = selection;
    const valArray = this.getValue().split('\n');
    let text = '';
    if (startLineNumber === endLineNumber) {
      text = valArray[startLineNumber - 1].slice(startColumn - 1, endColumn - 1);
    } else {
      const startLineText = valArray[startLineNumber - 1].slice(startColumn - 1);
      const endLineText = valArray[endLineNumber - 1].slice(0, endColumn - 1);

      for (let i = startLineNumber, k = endLineNumber - 1; i < k; i += 1) {
        text += `${valArray[i]}`;
        if (i !== k - 1) text += `\n`;
      }
      text = text
        ? [startLineText, text, endLineText].join('\n')
        : [startLineText, endLineText].join('\n');
    }
    return text;
  }

  replaceSelectedText(text, select = undefined) {
    const forceMoveMarkers = !select;
    this.executeEdits('', [{ range: this.getSelection(), text, forceMoveMarkers }]);
  }

  moveCursor(dx = 0, dy = 0) {
    const pos = this.getPosition();
    pos.column += dx;
    pos.lineNumber += dy;
    this.setPosition(pos);
  }

  /**
   * Adjust existing selection to select text within the original selection.
   * - If `selectedText` is not supplied, we fetch selected text with
   *
   * ALGORITHM:
   *
   * MULTI-LINE SELECTION
   * 1. Find line that contains `toSelect` text.
   * 2. Using the index of this line and the position of `toSelect` text in it,
   * construct:
   *   * newStartLineNumber
   *   * newStartColumn
   *
   * SINGLE-LINE SELECTION
   * 1. Use `startLineNumber` from the current selection as `newStartLineNumber`
   * 2. Find the position of `toSelect` text in it to get `newStartColumn`
   *
   * 3. `newEndLineNumber` — Since this method is supposed to be used with
   * markdown decorators that are pretty short, the `newEndLineNumber` is
   * suggested to be assumed the same as the startLine.
   * 4. `newEndColumn` — pretty obvious
   * 5. Adjust the start and end positions of the current selection
   * 6. Re-set selection on the instance
   *
   * @param {string} toSelect - New text to select within current selection.
   * @param {string} selectedText - Currently selected text. It's just a
   * shortcut: If it's not supplied, we fetch selected text from the instance
   */
  selectWithinSelection(toSelect, selectedText) {
    const currentSelection = this.getSelection();
    if (currentSelection.isEmpty() || !toSelect) {
      return;
    }
    const text = selectedText || this.getSelectedText(currentSelection);
    let lineShift;
    let newStartLineNumber;
    let newStartColumn;

    const textLines = text.split('\n');

    if (textLines.length > 1) {
      // Multi-line selection
      lineShift = textLines.findIndex((line) => line.indexOf(toSelect) !== -1);
      newStartLineNumber = currentSelection.startLineNumber + lineShift;
      newStartColumn = textLines[lineShift].indexOf(toSelect) + 1;
    } else {
      // Single-line selection
      newStartLineNumber = currentSelection.startLineNumber;
      newStartColumn = currentSelection.startColumn + text.indexOf(toSelect);
    }

    const newEndLineNumber = newStartLineNumber;
    const newEndColumn = newStartColumn + toSelect.length;

    const newSelection = currentSelection
      .setStartPosition(newStartLineNumber, newStartColumn)
      .setEndPosition(newEndLineNumber, newEndColumn);

    this.setSelection(newSelection);
  }
}
