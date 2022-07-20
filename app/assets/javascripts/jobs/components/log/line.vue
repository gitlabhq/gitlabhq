<script>
import { linkRegex } from '../../utils';

import LineNumber from './line_number.vue';

export default {
  functional: true,
  props: {
    line: {
      type: Object,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  render(h, { props }) {
    const { line, path, searchResults } = props;

    const chars = line.content.map((content) => {
      return h(
        'span',
        {
          class: ['gl-white-space-pre-wrap', content.style],
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
                class: 'gl-reset-color! gl-text-decoration-underline',
                rel: 'nofollow noopener noreferrer', // eslint-disable-line @gitlab/require-i18n-strings
              },
            },
            chunk,
          );
        }),
      );
    });

    let applyHighlight = false;

    if (searchResults.length > 0) {
      const linesToHighlight = searchResults.map((searchResultLine) => searchResultLine.lineNumber);

      linesToHighlight.forEach((num) => {
        if (num === line.lineNumber) {
          applyHighlight = true;
        }
      });
    }

    return h(
      'div',
      {
        class: ['js-line', 'log-line', applyHighlight ? 'gl-bg-gray-500' : ''],
      },
      [
        h(LineNumber, {
          props: {
            lineNumber: line.lineNumber,
            path,
          },
        }),
        ...chars,
      ],
    );
  },
};
</script>
