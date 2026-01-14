import * as ProseMirror from '@tiptap/pm/model';
import { replaceCommentsWith } from '~/lib/utils/dom_utils';

export const transformQuickActions = (markdown) => {
  // ensure 3 newlines after all quick actions so that
  // any reference style links after it get correctly parsed
  return markdown.replace(/^\/(.+?)\n/gm, '/$1\n\n\n');
};

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

      return { document: doc };
    },
  };
};
