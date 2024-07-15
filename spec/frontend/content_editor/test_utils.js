import { flatMap } from 'lodash';
import { Node } from '@tiptap/core';
import { Editor } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import * as builtInExtensions from '~/content_editor/extensions';

export const DEFAULT_WAIT_TIMEOUT = 100;

export const emitEditorEvent = ({ tiptapEditor, event, params = {} }) => {
  tiptapEditor.emit(event, { editor: tiptapEditor, ...params });

  return nextTick();
};

export const createTransactionWithMeta = (metaKey, metaValue) => {
  return {
    getMeta: (key) => (key === metaKey ? metaValue : null),
  };
};

/**
 * Creates an instance of the Tiptap Editor class
 * with a minimal configuration for testing purposes.
 *
 * It only includes the Document, Text, and Paragraph
 * extensions.
 *
 * @param {Array} config.extensions One or more extensions to
 * include in the editor
 * @returns An instance of a Tiptap’s Editor class
 */
export const createTestEditor = ({ extensions = [] } = {}) => {
  return new Editor({
    extensions: [
      builtInExtensions.Document,
      builtInExtensions.Text,
      builtInExtensions.Paragraph,
      ...extensions,
    ],
  });
};

export const mockChainedCommands = (editor, commandNames = []) => {
  const commandMocks = commandNames.reduce(
    (accum, commandName) => ({
      ...accum,
      [commandName]: jest.fn(),
    }),
    {},
  );

  Object.keys(commandMocks).forEach((commandName) => {
    commandMocks[commandName].mockReturnValue(commandMocks);
  });

  jest.spyOn(editor, 'chain').mockImplementation(() => commandMocks);

  return commandMocks;
};

/**
 * Creates a Content Editor extension for testing
 * purposes.
 *
 * @param {Array} config.commands A list of command names
 * to include in the test extension. This utility will create
 * Jest mock functions for each command name.
 * @returns An object with the following properties:
 *
 * tiptapExtension A Node tiptap extension
 * commandMocks Jest mock functions for each created command
 * serializer A markdown serializer for the extension
 */
export const createTestContentEditorExtension = ({ commands = [] } = {}) => {
  const commandMocks = commands.reduce(
    (accum, commandName) => ({
      ...accum,
      [commandName]: jest.fn(),
    }),
    {},
  );

  return {
    commandMocks,
    tiptapExtension: Node.create({
      name: 'label',
      priority: 101,
      inline: true,
      group: 'inline',
      addCommands() {
        return commands.reduce(
          (accum, commandName) => ({
            ...accum,
            [commandName]:
              (...params) =>
              () =>
                commandMocks[commandName](...params),
          }),
          {},
        );
      },
      addAttributes() {
        return {
          labelName: {
            default: null,
            parseHTML: (element) => element.dataset.labelName,
          },
        };
      },
      parseHTML() {
        return [
          {
            tag: 'span[data-reference="label"]',
          },
        ];
      },
      renderHTML({ HTMLAttributes }) {
        return ['span', HTMLAttributes, 0];
      },
    }),
    serializer: (state, node) => {
      state.write(`~${node.attrs.labelName}`);
      state.closeBlock(node);
    },
  };
};

export const triggerNodeInputRule = ({ tiptapEditor, inputRuleText }) => {
  const { view } = tiptapEditor;
  const { state } = tiptapEditor;
  const { selection } = state;

  // Triggers the event handler that input rules listen to
  view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, inputRuleText));
};

export const triggerMarkInputRule = ({ tiptapEditor, inputRuleText }) => {
  const { view } = tiptapEditor;

  tiptapEditor.chain().setContent(inputRuleText).setTextSelection(1).run();

  const { state } = tiptapEditor;
  const { selection } = state;

  // Triggers the event handler that input rules listen to
  view.someProp('handleTextInput', (f) =>
    f(view, selection.from, inputRuleText.length + 1, inputRuleText),
  );
};

export const triggerKeyboardInput = ({ tiptapEditor, key, shiftKey = false }) => {
  let isCaptured = false;
  tiptapEditor.view.someProp('handleKeyDown', (f) => {
    isCaptured = f(tiptapEditor.view, new KeyboardEvent('keydown', { key, shiftKey }));
    return isCaptured;
  });
  return isCaptured;
};

/**
 * Executes an action that triggers a transaction in the
 * tiptap Editor. Returns a promise that resolves
 * after the transaction completes
 * @param {*} params.tiptapEditor Tiptap editor
 * @param {*} params.action A function that triggers a transaction in the tiptap Editor
 * @returns A promise that resolves when the transaction completes
 */
export const waitUntilNextDocTransaction = ({ tiptapEditor, action = () => {} }) => {
  return new Promise((resolve) => {
    const handleTransaction = () => {
      tiptapEditor.off('update', handleTransaction);
      resolve();
    };

    tiptapEditor.on('update', handleTransaction);
    action();
  });
};

export const waitUntilTransaction = ({ tiptapEditor, number, action }) => {
  return new Promise((resolve) => {
    let counter = 0;
    const handleTransaction = () => {
      counter += 1;
      if (counter === number) {
        tiptapEditor.off('update', handleTransaction);
        resolve();
      }
    };

    tiptapEditor.on('update', handleTransaction);
    action();
  });
};

export const sleep = (time = DEFAULT_WAIT_TIMEOUT) => {
  jest.useRealTimers();
  const promise = new Promise((resolve) => {
    setTimeout(resolve, time);
  });
  jest.useFakeTimers();

  return promise;
};

export const expectDocumentAfterTransaction = ({ tiptapEditor, number, expectedDoc, action }) => {
  return new Promise((resolve) => {
    let counter = 0;
    const handleTransaction = async () => {
      counter += 1;
      if (counter === number) {
        expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
        tiptapEditor.off('update', handleTransaction);
        await waitForPromises();
        resolve();
      }
    };

    tiptapEditor.on('update', handleTransaction);
    action();
  });
};

export const createTiptapEditor = (extensions = []) => {
  const { Document, Text, Paragraph, Sourcemap, ...otherExtensions } = builtInExtensions;
  return createTestEditor({
    extensions: [...flatMap(otherExtensions), ...extensions],
  });
};
