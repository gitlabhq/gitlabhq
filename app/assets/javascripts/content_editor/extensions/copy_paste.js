import OrderedMap from 'orderedmap';
import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Schema, Slice, DOMParser as ProseMirrorDOMParser, DOMSerializer } from '@tiptap/pm/model';
import { handlePaste as handleTablePaste, isInTable, CellSelection } from '@tiptap/pm/tables';
import { uniqueId } from 'lodash-es';
import { s__, __ } from '~/locale';
import { sanitize } from '~/lib/dompurify';
import { VARIANT_DANGER } from '~/alert';
import createMarkdownDeserializer from '../services/gl_api_markdown_deserializer';
import { ALERT_EVENT, EXTENSION_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';
import CodeSuggestion from './code_suggestion';
import Diagram from './diagram';
import Frontmatter from './frontmatter';
import { loadingPlugin, findLoader } from './loading';

const TEXT_FORMAT = 'text/plain';
const GFM_FORMAT = 'text/x-gfm';
const HTML_FORMAT = 'text/html';
const VS_CODE_FORMAT = 'vscode-editor-data';
const CODE_BLOCK_NODE_TYPES = [
  CodeBlockHighlight.name,
  CodeSuggestion.name,
  Diagram.name,
  Frontmatter.name,
];

// Strips the span mark and div/pre nodes so stray wrapper artifacts from
// external HTML (e.g. Excel, Google Sheets) don't end up in the document.
function buildPasteSchema(schema) {
  const pasteSchemaSpec = { ...schema.spec };
  pasteSchemaSpec.marks = OrderedMap.from(pasteSchemaSpec.marks).remove('span');
  pasteSchemaSpec.nodes = OrderedMap.from(pasteSchemaSpec.nodes).remove('div').remove('pre');
  return new Schema(pasteSchemaSpec);
}

function parseHTML(schema, html) {
  const parser = new DOMParser();
  const startTag = '<body>';
  const endTag = '</body>';
  const { body } = parser.parseFromString(startTag + html + endTag, 'text/html');
  return { document: ProseMirrorDOMParser.fromSchema(schema).parse(body) };
}

function parseHTMLSlice(schema, html) {
  const parser = new DOMParser();
  const { body } = parser.parseFromString(`<body>${sanitize(html)}</body>`, 'text/html');
  return ProseMirrorDOMParser.fromSchema(schema).parseSlice(body);
}

function hasTableCells(html) {
  return /<t[dh][\s>]/i.test(html);
}

// Extracts the first <table> as outerHTML when it contains more than one
// cell. Tables copied from the rich text editor are wrapped in <div> elements
// (see the Table extension's renderHTML), which prevents prosemirror-tables'
// pastedCells() from finding the cells. Orphan <tr>/<td> markup (without a
// <table> ancestor) is dropped entirely by the HTML parser, so it is wrapped
// in a <table> first. Single-cell content returns null so it keeps flowing
// through the markdown-based paste path, preserving GFM fidelity.
function extractMultiCellTableHTML(html) {
  const parser = new DOMParser();
  let { body } = parser.parseFromString(`<body>${sanitize(html)}</body>`, 'text/html');
  let table = body.querySelector('table');

  // Wrap orphan rows before sanitizing: DOMPurify drops <tr>/<td> structure
  // that has no <table> ancestor.
  if (!table && /<tr[\s>]/i.test(html)) {
    ({ body } = parser.parseFromString(
      `<body>${sanitize(`<table>${html}</table>`)}</body>`,
      'text/html',
    ));
    table = body.querySelector('table');
  }

  return table && table.querySelectorAll('td, th').length > 1 ? table.outerHTML : null;
}

// The async Clipboard API is only available in secure contexts (HTTPS or
// localhost) and clipboard.read() is missing in some browsers (Firefox < 127).
export function canReadClipboard() {
  // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
  return Boolean(window.isSecureContext && navigator.clipboard?.read);
}

// Reads the clipboard outside a paste event (e.g. from a menu action).
// Requires clipboard-read permission; the browser may prompt the user.
// text/x-gfm is read opportunistically: most browsers don't expose custom
// formats through the async Clipboard API, so GFM fidelity is usually lost
// compared to a keyboard paste.
async function readClipboardContent() {
  // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
  const items = await navigator.clipboard.read();
  const readType = async (type) => {
    const item = items.find(({ types }) => types.includes(type));
    if (!item) return '';
    const blob = await item.getType(type);
    return blob.text();
  };

  return {
    gfmContent: await readType(GFM_FORMAT),
    htmlContent: await readType(HTML_FORMAT),
    textContent: await readType(TEXT_FORMAT),
  };
}

function serializeCellsToText(fragment) {
  const rows = [];
  fragment.forEach((row) => {
    const cells = [];
    // Replace embedded tabs/newlines so the tab-separated grid stays aligned
    // when pasted into spreadsheet applications.
    row.forEach((cell) => cells.push(cell.textContent.replace(/[\t\r\n]+/g, ' ')));
    rows.push(cells.join('\t'));
  });
  return rows.join('\n');
}

export default Extension.create({
  name: 'copyPaste',
  priority: EXTENSION_PRIORITY_HIGHEST,
  addOptions() {
    return {
      renderMarkdown: null,
      serializer: null,
    };
  },
  addCommands() {
    const alertError = (message) => {
      this.options.eventHub.$emit(ALERT_EVENT, { message, variant: VARIANT_DANGER });
    };
    // Scoped to the clipboard read so processing failures don't surface a
    // misleading permissions message. Resolves to null on failure.
    const readClipboard = () =>
      readClipboardContent().catch(() => {
        alertError(
          s__(
            'ContentEditor|Unable to read the clipboard. Check your browser clipboard permissions and try again.',
          ),
        );
        return null;
      });
    const alertPasteError = () =>
      alertError(__('An error occurred while pasting text in the editor. Please try again.'));

    return {
      pasteContent:
        (content = '', processMarkdown = true) =>
        () => {
          const { editor, options } = this;
          const { renderMarkdown, eventHub } = options;
          const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

          const pasteSchema = buildPasteSchema(editor.schema);

          const promise = processMarkdown
            ? deserializer.deserialize({ schema: pasteSchema, markdown: content })
            : Promise.resolve(parseHTML(pasteSchema, content));
          const loaderId = uniqueId('loading');

          Promise.resolve()
            .then(() => {
              editor
                .chain()
                .deleteSelection()
                .setMeta(loadingPlugin, {
                  add: { loaderId, pos: editor.state.selection.from },
                })
                .run();

              return promise;
            })
            .then(async ({ document }) => {
              if (!document) return;

              const pos = findLoader(editor.state, loaderId);
              if (!pos) return;

              const { firstChild, childCount } = document.content;
              const toPaste =
                childCount === 1 && firstChild.type.name === 'paragraph'
                  ? firstChild.content
                  : document.content;

              editor
                .chain()
                .setMeta(loadingPlugin, { remove: { loaderId } })
                .insertContentAt(pos, toPaste.toJSON(), {
                  updateSelection: false,
                })
                .run();
            })
            .catch(() => {
              eventHub.$emit(ALERT_EVENT, {
                message: __(
                  'An error occurred while pasting text in the editor. Please try again.',
                ),
                variant: VARIANT_DANGER,
              });
            });

          return true;
        },
      pasteFromClipboardIntoCell:
        () =>
        ({ editor }) => {
          // readClipboard never rejects, so a rejection here is a processing
          // error, not a clipboard permissions problem.
          readClipboard()
            .then((content) => {
              if (!content) return;

              const { gfmContent, htmlContent, textContent } = content;
              if (gfmContent) {
                editor.commands.pasteContent(gfmContent, true);
              } else if (htmlContent || textContent) {
                editor.commands.pasteContent(htmlContent || textContent, !htmlContent);
              }
            })
            .catch(alertPasteError);

          return true;
        },
      pasteFromClipboardIntoTable:
        () =>
        ({ editor, view }) => {
          readClipboard()
            .then((content) => {
              if (!content) return;

              const { gfmContent, htmlContent, textContent } = content;
              const tableHTML = htmlContent && extractMultiCellTableHTML(htmlContent);

              if (tableHTML) {
                const pasteSlice = parseHTMLSlice(buildPasteSchema(view.state.schema), tableHTML);
                const slice = Slice.fromJSON(view.state.schema, pasteSlice.toJSON());
                if (handleTablePaste(view, null, slice)) return;
              }

              if (gfmContent) {
                editor.commands.pasteContent(gfmContent, true);
              } else if (htmlContent || textContent) {
                editor.commands.pasteContent(htmlContent || textContent, !htmlContent);
              }
            })
            .catch(alertPasteError);

          return true;
        },
    };
  },
  addProseMirrorPlugins() {
    let pasteRaw = false;

    const handleCutAndCopy = (view, event) => {
      const slice = view.state.selection.content();
      let gfmContent = this.options.serializer.serialize({ doc: slice.content });
      const gfmContentWithoutSingleTableCell = gfmContent.replace(
        /^<table>[\s\n]*<tr>[\s\n]*<t[hd]>|<\/t[hd]>[\s\n]*<\/tr>[\s\n]*<\/table>[\s\n]*$/gim,
        '',
      );
      const containsSingleTableCell = !/<t[hd]>/.test(gfmContentWithoutSingleTableCell);

      if (containsSingleTableCell) {
        gfmContent = gfmContentWithoutSingleTableCell;
      }
      const documentFragment = DOMSerializer.fromSchema(view.state.schema).serializeFragment(
        slice.content,
      );
      const div = document.createElement('div');
      div.appendChild(documentFragment);

      let textContent = div.innerText;
      let htmlContent = div.innerHTML;

      let selectedCellCount = 0;
      if (view.state.selection instanceof CellSelection) {
        view.state.selection.forEachCell(() => {
          selectedCellCount += 1;
        });
      }

      // A CellSelection slice contains bare tableRow nodes, which serialize to
      // orphan <tr> elements that HTML parsers drop on paste. Wrap them in a
      // <table> so pasting into a table distributes cells (and spreadsheets
      // understand the clipboard content).
      if (selectedCellCount > 1 && slice.content.firstChild?.type.name === 'tableRow') {
        const table = document.createElement('table');
        const tbody = document.createElement('tbody');
        tbody.appendChild(
          DOMSerializer.fromSchema(view.state.schema).serializeFragment(slice.content),
        );
        table.appendChild(tbody);

        htmlContent = table.outerHTML;
        textContent = serializeCellsToText(slice.content);
      }

      event.clipboardData.setData(TEXT_FORMAT, textContent);
      event.clipboardData.setData(HTML_FORMAT, htmlContent);
      event.clipboardData.setData(GFM_FORMAT, gfmContent);

      event.preventDefault();
      event.stopPropagation();
    };

    return [
      new Plugin({
        key: new PluginKey('copyPaste'),
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
            const textContent = clipboardData.getData(TEXT_FORMAT);
            const htmlContent = clipboardData.getData(HTML_FORMAT);

            const { from, to } = view.state.selection;
            const isCodeBlockActive = CODE_BLOCK_NODE_TYPES.some((type) =>
              this.editor.isActive(type),
            );

            // When pasting multiple table cells into a table, delegate to
            // prosemirror-tables' handlePaste, which distributes cell content
            // across rows and columns and auto-expands the table when the
            // pasted area overflows it. Single-cell pastes keep using the
            // markdown-based paste path below.
            if (
              !pasteRaw &&
              !isCodeBlockActive &&
              isInTable(view.state) &&
              htmlContent &&
              hasTableCells(htmlContent)
            ) {
              const tableHTML = extractMultiCellTableHTML(htmlContent);
              if (tableHTML) {
                // Parse with the restricted paste schema, then rehydrate in
                // the editor schema (node types are schema-bound).
                const pasteSlice = parseHTMLSlice(buildPasteSchema(view.state.schema), tableHTML);
                const slice = Slice.fromJSON(view.state.schema, pasteSlice.toJSON());
                if (handleTablePaste(view, event, slice)) return true;
              }
            }

            if (pasteRaw || isCodeBlockActive) {
              const isMarkdownCodeBlockActive = this.editor.isActive(CodeBlockHighlight.name, {
                language: 'markdown',
              });

              let contentToInsert;
              if (isMarkdownCodeBlockActive) {
                contentToInsert = gfmContent || textContent;
              } else if (pasteRaw) {
                contentToInsert = textContent.replace(/^\s+|\s+$/gm, '');
              } else {
                contentToInsert = textContent;
              }

              if (!contentToInsert) return false;

              if (isCodeBlockActive) contentToInsert = { type: 'text', text: contentToInsert };
              else {
                contentToInsert = {
                  type: 'paragraph',
                  content: contentToInsert
                    .split('\n')
                    .map((text) => [{ type: 'text', text }, { type: 'hardBreak' }])
                    .flat(),
                };
              }

              this.editor.commands.insertContentAt({ from, to }, contentToInsert);
              return true;
            }

            if (!textContent) return false;

            const hasHTML = clipboardData.types.some((type) => type === HTML_FORMAT);
            const hasVsCode = clipboardData.types.some((type) => type === VS_CODE_FORMAT);
            const vsCodeMeta = hasVsCode ? JSON.parse(clipboardData.getData(VS_CODE_FORMAT)) : {};
            const language = vsCodeMeta.mode;

            if (hasVsCode) {
              return this.editor.commands.pasteContent(
                language === 'markdown' ? textContent : `\`\`\`${language}\n${textContent}\n\`\`\``,
                true,
              );
            }

            if (gfmContent) {
              return this.editor.commands.pasteContent(gfmContent, true);
            }

            const preStartRegex = /^<pre[^>]*lang="markdown"[^>]*>/;
            const preEndRegex = /<\/pre>$/;
            const htmlContentWithoutMeta = htmlContent?.replace(/^<meta[^>]*>/, '');
            const pastingMarkdownBlock =
              hasHTML &&
              preStartRegex.test(htmlContentWithoutMeta) &&
              preEndRegex.test(htmlContentWithoutMeta);

            if (pastingMarkdownBlock) return this.editor.commands.pasteContent(textContent, true);

            return this.editor.commands.pasteContent(hasHTML ? htmlContent : textContent, !hasHTML);
          },
        },
      }),
    ];
  },
});
