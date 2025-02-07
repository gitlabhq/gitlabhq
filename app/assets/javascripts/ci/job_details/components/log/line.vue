<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { getLocationHash } from '~/lib/utils/url_utility';
import { linkRegex } from './utils';
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
    isHighlighted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  render(h, { props }) {
    const { line, path, isHighlighted } = props;

    const parts = line.content.map((content) => {
      return h(
        'span',
        {
          class: [content.style],
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
              },
            },
            chunk,
          );
        }),
      );
    });

    let applyHashHighlight = false;

    if (window.location.hash) {
      const hash = getLocationHash();
      const lineToMatch = `L${line.lineNumber}`;

      if (hash === lineToMatch) {
        applyHashHighlight = true;
      }
    }

    return h(
      'div',
      {
        class: [
          'js-log-line',
          'job-log-line',
          { 'job-log-line-highlight': isHighlighted || applyHashHighlight },
        ],
      },
      [
        h(LineNumber, {
          props: {
            lineNumber: line.lineNumber,
            path,
          },
        }),
        ...(line.time
          ? [
              h(
                'span',
                {
                  class: 'job-log-time',
                },
                line.time,
              ),
            ]
          : []),
        h(
          'span',
          {
            class: 'job-log-line-content',
          },
          parts,
        ),
      ],
    );
  },
};
</script>
