import { MarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import editorExtensions from './editor_extensions';

const nodes = editorExtensions.nodes.reduce(
  (ns, { name, toMarkdown }) => ({
    ...ns,
    [name]: toMarkdown,
  }),
  {},
);

const marks = editorExtensions.marks.reduce(
  (ms, { name, toMarkdown }) => ({
    ...ms,
    [name]: toMarkdown,
  }),
  {},
);

export default new MarkdownSerializer(nodes, marks);
