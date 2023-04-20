import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { __ } from '~/locale';
import { VARIANT_DANGER } from '~/alert';
import createMarkdownDeserializer from '../services/gl_api_markdown_deserializer';
import { ALERT_EVENT, EXTENSION_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';
import Diagram from './diagram';
import Frontmatter from './frontmatter';

const TEXT_FORMAT = 'text/plain';
const HTML_FORMAT = 'text/html';
const VS_CODE_FORMAT = 'vscode-editor-data';
const CODE_BLOCK_NODE_TYPES = [CodeBlockHighlight.name, Diagram.name, Frontmatter.name];

export default Extension.create({
  name: 'pasteMarkdown',
  priority: EXTENSION_PRIORITY_HIGHEST,
  addOptions() {
    return {
      renderMarkdown: null,
    };
  },
  addCommands() {
    return {
      pasteMarkdown: (markdown) => () => {
        const { editor, options } = this;
        const { renderMarkdown, eventHub } = options;
        const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

        deserializer
          .deserialize({ schema: editor.schema, markdown })
          .then(({ document }) => {
            if (!document) {
              return;
            }

            const { state, view } = editor;
            const { tr, selection } = state;
            const { firstChild } = document.content;
            const content =
              document.content.childCount === 1 && firstChild.type.name === 'paragraph'
                ? firstChild.content
                : document.content;

            if (selection.to - selection.from > 0) {
              tr.replaceWith(selection.from, selection.to, content);
            } else {
              tr.insert(selection.from, content);
            }

            view.dispatch(tr);
          })
          .catch(() => {
            eventHub.$emit(ALERT_EVENT, {
              message: __('An error occurred while pasting text in the editor. Please try again.'),
              variant: VARIANT_DANGER,
            });
          });

        return true;
      },
    };
  },
  addProseMirrorPlugins() {
    let pasteRaw = false;

    return [
      new Plugin({
        key: new PluginKey('pasteMarkdown'),
        props: {
          handleKeyDown: (_, event) => {
            pasteRaw = event.key === 'v' && (event.metaKey || event.ctrlKey) && event.shiftKey;
          },

          handlePaste: (view, event) => {
            const { clipboardData } = event;
            const content = clipboardData.getData(TEXT_FORMAT);
            const { state } = view;
            const { tr, selection } = state;
            const { from, to } = selection;

            if (pasteRaw) {
              tr.insertText(content.replace(/^\s+|\s+$/gm, ''), from, to);
              view.dispatch(tr);
              return true;
            }

            const hasHTML = clipboardData.types.some((type) => type === HTML_FORMAT);
            const hasVsCode = clipboardData.types.some((type) => type === VS_CODE_FORMAT);
            const vsCodeMeta = hasVsCode ? JSON.parse(clipboardData.getData(VS_CODE_FORMAT)) : {};
            const language = vsCodeMeta.mode;

            if (!content || (hasHTML && !hasVsCode) || (hasVsCode && language !== 'markdown')) {
              return false;
            }

            // if a code block is active, paste as plain text
            if (CODE_BLOCK_NODE_TYPES.some((type) => this.editor.isActive(type))) {
              return false;
            }

            this.editor.commands.pasteMarkdown(content);

            return true;
          },
        },
      }),
    ];
  },
});
