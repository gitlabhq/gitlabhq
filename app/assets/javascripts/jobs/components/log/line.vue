<script>
import linkifyHtml from 'linkifyjs/html';
import { sanitize } from '~/lib/dompurify';
import { isAbsolute } from '~/lib/utils/url_utility';
import LineNumber from './line_number.vue';

const linkifyOptions = {
  attributes: {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    rel: 'nofollow noopener',
  },
  className: 'gl-reset-color!',
  defaultProtocol: 'https',
  validate: {
    email: false,
    url(value) {
      return isAbsolute(value);
    },
  },
};

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
  },
  render(h, { props }) {
    const { line, path } = props;

    const chars = line.content.map(content => {
      const linkfied = linkifyHtml(content.text, linkifyOptions);
      return h('span', {
        class: ['gl-white-space-pre-wrap', content.style],
        domProps: {
          innerHTML: sanitize(linkfied, {
            ALLOWED_TAGS: ['a'],
          }),
        },
      });
    });

    return h('div', { class: 'js-line log-line' }, [
      h(LineNumber, {
        props: {
          lineNumber: line.lineNumber,
          path,
        },
      }),
      ...chars,
    ]);
  },
};
</script>
