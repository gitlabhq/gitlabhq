import { insertMarkdownText } from '~/lib/utils/text_markdown';
import { EDITOR_TOOLBAR_BUTTON_GROUPS, EXTENSION_MARKDOWN_BUTTONS } from '../constants';

export class EditorMarkdownExtension {
  static get extensionName() {
    return 'EditorMarkdown';
  }

  onSetup(instance) {
    this.toolbarButtons = [];
    this.actions = [];
    if (instance.toolbar) {
      this.setupToolbar(instance);
    }
  }
  onBeforeUnuse(instance) {
    const ids = this.toolbarButtons.map((item) => item.id);
    if (instance.toolbar) {
      instance.toolbar.removeItems(ids);
    }
    this.actions.forEach((action) => {
      action.dispose();
    });
    this.actions = [];
  }

  setupToolbar(instance) {
    this.toolbarButtons = EXTENSION_MARKDOWN_BUTTONS.map((btn) => {
      if (btn.data.mdShortcuts) {
        this.actions.push(
          instance.addAction({
            id: btn.id,
            label: btn.label,
            keybindings: btn.data.mdShortcuts,
            run(inst) {
              inst.insertMarkdown(btn.data);
            },
          }),
        );
      }
      return {
        ...btn,
        icon: btn.id,
        group: EDITOR_TOOLBAR_BUTTON_GROUPS.edit,
        category: 'tertiary',
        onClick: (e) => instance.insertMarkdown(e),
      };
    });
    instance.toolbar.addItems(this.toolbarButtons);
  }

  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      getSelectedText: (instance, selection = instance.getSelection()) => {
        const { startLineNumber, endLineNumber, startColumn, endColumn } = selection;
        const valArray = instance.getValue().split('\n');
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
      },
      replaceSelectedText: (instance, text, select) => {
        const forceMoveMarkers = !select;
        instance.executeEdits('', [{ range: instance.getSelection(), text, forceMoveMarkers }]);
      },
      moveCursor: (instance, dx = 0, dy = 0) => {
        const pos = instance.getPosition();
        pos.column += dx;
        pos.lineNumber += dy;
        instance.setPosition(pos);
      },
      insertMarkdown: (instance, e) => {
        const {
          mdTag: tag,
          mdBlock: blockTag,
          mdPrepend,
          mdSelect: select,
        } = e.currentTarget?.dataset || e;

        insertMarkdownText({
          tag,
          blockTag,
          wrap: !mdPrepend,
          select,
          selected: instance.getSelectedText(),
          text: instance.getValue(),
          editor: instance,
        });
        instance.focus();
      },
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
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance. Is passed automatically.
       * @param {string} toSelect - New text to select within current selection.
       * @param {string} selectedText - Currently selected text. It's just a
       * shortcut: If it's not supplied, we fetch selected text from the instance
       */
      selectWithinSelection: (instance, toSelect, selectedText) => {
        const currentSelection = instance.getSelection();
        if (currentSelection.isEmpty() || !toSelect) {
          return;
        }
        const text = selectedText || instance.getSelectedText(currentSelection);
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

        instance.setSelection(newSelection);
      },
    };
  }
}
