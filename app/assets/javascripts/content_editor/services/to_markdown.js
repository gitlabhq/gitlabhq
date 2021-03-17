import { MarkdownSerializer, defaultMarkdownSerializer } from 'prosemirror-markdown';

const toMarkdown = (document) => {
  const serializer = new MarkdownSerializer(defaultMarkdownSerializer.nodes, {
    ...defaultMarkdownSerializer.marks,
    bold: {
      // creates a bold alias for the strong mark converter
      ...defaultMarkdownSerializer.marks.strong,
    },
  });

  return serializer.serialize(document);
};

export default toMarkdown;
