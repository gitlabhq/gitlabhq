import * as ProseMirror from '@tiptap/pm/model';
import { replaceCommentsWith } from '~/lib/utils/dom_utils';

const CODE_FENCE = /^ {0,3}(`{3,}|~{3,})(.*)$/;

const openingFence = (line) => {
  const [, fence, info] = CODE_FENCE.exec(line) || [];

  if (!fence || (fence.startsWith('`') && info.includes('`'))) return null;

  return fence;
};

const closesFence = (line, fence) => {
  const [, closing, rest] = CODE_FENCE.exec(line) || [];

  return (
    Boolean(closing) && closing[0] === fence[0] && closing.length >= fence.length && !rest.trim()
  );
};

// ensure 3 newlines after all quick actions so that
// any reference style links after it get correctly parsed
const isolateQuickAction = (line) => line.replace(/^\/(.+)$/, '/$1\n\n');

export const transformQuickActions = (markdown) => {
  let fence = null;

  return markdown
    .split('\n')
    .map((line, index, lines) => {
      if (fence) {
        if (closesFence(line, fence)) fence = null;

        return line;
      }

      fence = openingFence(line);

      // The final line is skipped deliberately. The regex this replaced,
      // /^\/(.+?)\n/gm, needed a trailing newline to match, so a quick action
      // on the last line of a document without one was never isolated. Keeping
      // that behaviour avoids changing output here; the "a quick action without
      // a trailing newline" spec pins it.
      if (fence || index === lines.length - 1) return line;

      return isolateQuickAction(line);
    })
    .join('\n');
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
