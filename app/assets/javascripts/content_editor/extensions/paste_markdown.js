import OrderedMap from 'orderedmap';
import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Schema, DOMParser as ProseMirrorDOMParser, DOMSerializer } from '@tiptap/pm/model';
import { __ } from '~/locale';
import { VARIANT_DANGER } from '~/alert';
import createMarkdownDeserializer from '../services/gl_api_markdown_deserializer';
import { ALERT_EVENT, EXTENSION_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';
import Diagram from './diagram';
import Frontmatter from './frontmatter';

const TEXT_FORMAT = 'text/plain';
const GFM_FORMAT = 'text/x-gfm';
const HTML_FORMAT = 'text/html';
const VS_CODE_FORMAT = 'vscode-editor-data';
const CODE_BLOCK_NODE_TYPES = [CodeBlockHighlight.name, Diagram.name, Frontmatter.name];

function parseHTML(schema, html) {
  const parser = new DOMParser();
  const startTag = '<body>';
  const endTag = '</body>';
  const { body } = parser.parseFromString(startTag + html + endTag, 'text/html');
  return { document: ProseMirrorDOMParser.fromSchema(schema).parse(body) };
}

export default Extension.create({
  name: 'pasteMarkdown',
  priority: EXTENSION_PRIORITY_HIGHEST,
  addOptions() {
    return {
      renderMarkdown: null,
      serializer: null,
    };
  },
  addCommands() {
    return {
      pasteContent: (content = '', processMarkdown = true) => async () => {
        const { editor, options } = this;
        const { renderMarkdown, eventHub } = options;
        const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

        const pasteSchemaSpec = { ...editor.schema.spec };
        pasteSchemaSpec.marks = OrderedMap.from(pasteSchemaSpec.marks).remove('span');
        pasteSchemaSpec.nodes = OrderedMap.from(pasteSchemaSpec.nodes).remove('div').remove('pre');
        const schema = new Schema(pasteSchemaSpec);

        const promise = processMarkdown
          ? deserializer.deserialize({ schema, markdown: content })
          : Promise.resolve(parseHTML(schema, content));

        promise
          .then(({ document }) => {
            if (!document) return;

            const { firstChild } = document.content;
            const toPaste =
              document.content.childCount === 1 && firstChild.type.name === 'paragraph'
                ? firstChild.content
                : document.content;

            editor.commands.insertContent(toPaste.toJSON());
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

    const handleCutAndCopy = (view, event) => {
      const slice = view.state.selection.content();
      const gfmContent = this.options.serializer.serialize({ doc: slice.content });
      const documentFragment = DOMSerializer.fromSchema(view.state.schema).serializeFragment(
        slice.content,
      );
      const div = document.createElement('div');
      div.appendChild(documentFragment);

      event.clipboardData.setData(TEXT_FORMAT, div.innerText);
      event.clipboardData.setData(HTML_FORMAT, div.innerHTML);
      event.clipboardData.setData(GFM_FORMAT, gfmContent);

      event.preventDefault();
      event.stopPropagation();
    };

    return [
      new Plugin({
        key: new PluginKey('pasteMarkdown'),
        props: {
          handleDOMEvents: {
            copy: handleCutAndCopy,
            cut: (view, event) => {
              handleCutAndCopy(view, event);
              this.editor.commands.deleteSelection();
            },
          },
          handleKeyDown: (_, event) => {
            pasteRaw = event.key === 'v' && (event.metaKey || event.ctrlKey) && event.shiftKey;
          },

          handlePaste: (view, event) => {
            const { clipboardData } = event;

            const gfmContent = clipboardData.getData(GFM_FORMAT);

            if (gfmContent) {
              return this.editor.commands.pasteContent(gfmContent, true);
            }

            const textContent = clipboardData.getData(TEXT_FORMAT);
            const htmlContent = clipboardData.getData(HTML_FORMAT);

            const { from, to } = view.state.selection;

            if (pasteRaw) {
              this.editor.commands.insertContentAt(
                { from, to },
                textContent.replace(/^\s+|\s+$/gm, ''),
              );
              return true;
            }

            const hasHTML = clipboardData.types.some((type) => type === HTML_FORMAT);
            const hasVsCode = clipboardData.types.some((type) => type === VS_CODE_FORMAT);
            const vsCodeMeta = hasVsCode ? JSON.parse(clipboardData.getData(VS_CODE_FORMAT)) : {};
            const language = vsCodeMeta.mode;

            // if a code block is active, paste as plain text
            if (!textContent || CODE_BLOCK_NODE_TYPES.some((type) => this.editor.isActive(type))) {
              return false;
            }

            if (hasVsCode) {
              return this.editor.commands.pasteContent(
                language === 'markdown' ? textContent : `\`\`\`${language}\n${textContent}\n\`\`\``,
                true,
              );
            }

            return this.editor.commands.pasteContent(hasHTML ? htmlContent : textContent, !hasHTML);
          },
        },
      }),
    ];
  },
});
