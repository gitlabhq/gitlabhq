import { Node } from '@tiptap/core';
import { Document } from '@tiptap/extension-document';
import { Paragraph } from '@tiptap/extension-paragraph';
import { Text } from '@tiptap/extension-text';
import { Editor } from '@tiptap/vue-2';
import { builders, eq } from 'prosemirror-test-builder';

export const createDocBuilder = ({ tiptapEditor, names = {} }) => {
  const docBuilders = builders(tiptapEditor.schema, {
    p: { nodeType: 'paragraph' },
    ...names,
  });

  return { eq, builders: docBuilders };
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
    extensions: [Document, Text, Paragraph, ...extensions],
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
            [commandName]: (...params) => () => commandMocks[commandName](...params),
          }),
          {},
        );
      },
      addAttributes() {
        return {
          labelName: {
            default: null,
            parseHTML: (element) => {
              return { labelName: element.dataset.labelName };
            },
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
