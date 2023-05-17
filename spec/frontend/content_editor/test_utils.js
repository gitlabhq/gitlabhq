import { Node } from '@tiptap/core';
import { Document } from '@tiptap/extension-document';
import { Paragraph } from '@tiptap/extension-paragraph';
import { Text } from '@tiptap/extension-text';
import { Editor } from '@tiptap/vue-2';
import { builders, eq } from 'prosemirror-test-builder';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import Audio from '~/content_editor/extensions/audio';
import Blockquote from '~/content_editor/extensions/blockquote';
import Bold from '~/content_editor/extensions/bold';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Comment from '~/content_editor/extensions/comment';
import DescriptionItem from '~/content_editor/extensions/description_item';
import DescriptionList from '~/content_editor/extensions/description_list';
import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import Diagram from '~/content_editor/extensions/diagram';
import DrawioDiagram from '~/content_editor/extensions/drawio_diagram';
import Emoji from '~/content_editor/extensions/emoji';
import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';
import FootnoteReference from '~/content_editor/extensions/footnote_reference';
import FootnotesSection from '~/content_editor/extensions/footnotes_section';
import Frontmatter from '~/content_editor/extensions/frontmatter';
import Figure from '~/content_editor/extensions/figure';
import FigureCaption from '~/content_editor/extensions/figure_caption';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Highlight from '~/content_editor/extensions/highlight';
import Image from '~/content_editor/extensions/image';
import InlineDiff from '~/content_editor/extensions/inline_diff';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import ReferenceDefinition from '~/content_editor/extensions/reference_definition';
import Strike from '~/content_editor/extensions/strike';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableHeader from '~/content_editor/extensions/table_header';
import TableRow from '~/content_editor/extensions/table_row';
import TableOfContents from '~/content_editor/extensions/table_of_contents';
import TaskItem from '~/content_editor/extensions/task_item';
import TaskList from '~/content_editor/extensions/task_list';
import Video from '~/content_editor/extensions/video';
import HTMLMarks from '~/content_editor/extensions/html_marks';
import HTMLNodes from '~/content_editor/extensions/html_nodes';

export const createDocBuilder = ({ tiptapEditor, names = {} }) => {
  const docBuilders = builders(tiptapEditor.schema, {
    p: { nodeType: 'paragraph' },
    ...names,
  });

  return { eq, builders: docBuilders };
};

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

export const createTiptapEditor = (extensions = []) =>
  createTestEditor({
    extensions: [
      Audio,
      Blockquote,
      Bold,
      BulletList,
      Code,
      CodeBlockHighlight,
      Comment,
      DescriptionItem,
      DescriptionList,
      Details,
      DetailsContent,
      DrawioDiagram,
      Diagram,
      Emoji,
      FootnoteDefinition,
      FootnoteReference,
      FootnotesSection,
      Frontmatter,
      Figure,
      FigureCaption,
      HardBreak,
      Heading,
      HorizontalRule,
      ...HTMLMarks,
      ...HTMLNodes,
      Highlight,
      Image,
      InlineDiff,
      Italic,
      Link,
      ListItem,
      OrderedList,
      ReferenceDefinition,
      Strike,
      Table,
      TableCell,
      TableHeader,
      TableRow,
      TableOfContents,
      TaskItem,
      TaskList,
      Video,
      ...extensions,
    ],
  });
