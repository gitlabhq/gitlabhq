<script>
import { linkRegex } from './utils';
import LineNumber from './line_number.vue';

export default {
  functional: true,
  props: {
    line: {
      type: Object,
      required: true,
    },
    isHighlighted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  render(h, { props }) {
    const { line, isHighlighted } = props;

    const chars = line.content.map((content) => {
      return h(
        'span',
        {
          class: ['gl-whitespace-pre-wrap', content.style],
        },
        // Simple "tokenization": Split text in chunks of text
        // which alternate between text and urls.
        content.text.split(linkRegex).map((chunk) => {
          // Return normal string for non-links
          if (!chunk.match(linkRegex)) {
            return chunk;
          }
          return h(
            'a',
            {
              attrs: {
                href: chunk,
                class: '!gl-text-inherit gl-underline',
                rel: 'nofollow noopener noreferrer', // eslint-disable-line @gitlab/require-i18n-strings
                target: '_blank',
              },
            },
            chunk,
          );
        }),
      );
    });

    return h(
      'div',
      {
        class: ['gl-text-white', 'gl-pl-9', { 'gl-bg-gray-700': isHighlighted }],
      },
      [
        h(LineNumber, {
          props: {
            lineNumber: line.lineNumber,
            lineId: line.lineId,
          },
        }),
        ...chars,
      ],
    );
  },
};
</script>
