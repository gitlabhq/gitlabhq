import * as ProseMirror from '@tiptap/pm/model';
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import { replaceCommentsWith } from '~/lib/utils/dom_utils';

const markdownToAst = (markdown) => {
  return unified().use(remarkParse).parse(markdown);
};

export const transformQuickActions = (markdown) => {
  // ensure 3 newlines after all quick actions so that
  // any reference style links after it get correctly parsed
  return markdown.replace(/^\/(.+?)\n/gm, '/$1\n\n\n');
};

/**
 * Extracts link reference definitions from a markdown string.
 * This is useful for preserving reference definitions when
 * serializing a ProseMirror document back to markdown.
 *
 * @param {string} markdown
 * @returns {string}
 */
const extractReferenceDefinitions = (markdown) => {
  const ast = markdownToAst(markdown);

  return ast.children
    .filter((node) => {
      return node.type === 'definition';
    })
    .map((node) => {
      const { start, end } = node.position;
      return markdown.substring(start.offset, end.offset);
    })
    .join('\n');
};

const preserveMarkdown = () => gon.features?.preserveMarkdown;

/**
 * @param {{ render: (markdown: string) => Promise<{ body: string }> }} param
 */
export default ({ render }) => {
  return {
    /**
     * Converts a Markdown string into a ProseMirror document based
     * on a schema.
     *
     * @param {{ schema: ProseMirror.Schema, markdown: string }} params
     * @returns {{ document: ProseMirror.Node }}
     */
    deserialize: async ({ schema, markdown }) => {
      const transformedMarkdown = transformQuickActions(markdown);
      const html = markdown ? (await render(transformedMarkdown)).body : '<p></p>';
      const parser = new DOMParser();
      const { body } = parser.parseFromString(`<body>${html}</body>`, 'text/html');

      replaceCommentsWith(body, 'comment');

      // append original source as a comment that nodes can access
      body.append(document.createComment(transformedMarkdown));

      const doc = ProseMirror.DOMParser.fromSchema(schema).parse(body);

      if (preserveMarkdown())
        doc.attrs = {
          source: transformedMarkdown,
          referenceDefinitions: extractReferenceDefinitions(transformedMarkdown),
        };

      return { document: doc };
    },
  };
};
