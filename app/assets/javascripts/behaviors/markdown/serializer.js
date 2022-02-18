import { MarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import editorExtensions from './editor_extensions';

const nodes = editorExtensions
  .filter((extension) => extension.type === 'node')
  .reduce(
    (ns, { name, toMarkdown }) => ({
      ...ns,
      [name]: toMarkdown,
    }),
    {},
  );

const marks = editorExtensions
  .filter((extension) => extension.type === 'mark')
  .reduce(
    (ms, { name, toMarkdown }) => ({
      ...ms,
      [name]: toMarkdown,
    }),
    {},
  );

export default new MarkdownSerializer(nodes, marks);
