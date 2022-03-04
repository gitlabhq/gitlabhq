import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => {
  return {
    name: 'bold',
    schema: {
      parseDOM: [
        {
          tag: 'strong',
        },
      ],
      toDOM: () => ['strong', 0],
    },
    toMarkdown: defaultMarkdownSerializer.marks.strong,
  };
};
