<script>
import marked from 'marked';
import sanitize from 'sanitize-html';
import katex from 'katex';
import Prompt from './prompt.vue';

const renderer = new marked.Renderer();

/*
    Regex to match KaTex blocks.

    Supports the following:

    \begin{equation}<math>\end{equation}
    $$<math>$$
    inline $<math>$

    The matched text then goes through the KaTex renderer & then outputs the HTML
  */
const katexRegexString = `(
    ^\\\\begin{[a-zA-Z]+}\\s
    |
    ^\\$\\$
    |
    \\s\\$(?!\\$)
  )
    ((.|\\n)+?)
  (
    \\s\\\\end{[a-zA-Z]+}$
    |
    \\$\\$$
    |
    \\$
  )
  `
  .replace(/\s/g, '')
  .trim();

renderer.paragraph = t => {
  let text = t;
  let inline = false;

  if (typeof katex !== 'undefined') {
    const katexString = text
      .replace(/&amp;/g, '&')
      .replace(/&=&/g, '\\space=\\space') // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
      .replace(/<(\/?)em>/g, '_');
    const regex = new RegExp(katexRegexString, 'gi');
    const matchLocation = katexString.search(regex);
    const numberOfMatches = katexString.match(regex);

    if (numberOfMatches && numberOfMatches.length !== 0) {
      if (matchLocation > 0) {
        let matches = regex.exec(katexString);
        inline = true;

        while (matches !== null) {
          const renderedKatex = katex.renderToString(matches[0].replace(/\$/g, ''));
          text = `${text.replace(matches[0], ` ${renderedKatex}`)}`;
          matches = regex.exec(katexString);
        }
      } else {
        const matches = regex.exec(katexString);
        text = katex.renderToString(matches[2]);
      }
    }
  }

  return `<p class="${inline ? 'inline-katex' : ''}">${text}</p>`;
};

marked.setOptions({
  renderer,
});

export default {
  components: {
    prompt: Prompt,
  },
  props: {
    cell: {
      type: Object,
      required: true,
    },
  },
  computed: {
    markdown() {
      return sanitize(marked(this.cell.source.join('').replace(/\\/g, '\\\\')), {
        // allowedTags from GitLab's inline HTML guidelines
        // https://docs.gitlab.com/ee/user/markdown.html#inline-html
        allowedTags: [
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'h7',
          'h8',
          'br',
          'b',
          'i',
          'strong',
          'em',
          'a',
          'pre',
          'code',
          'img',
          'tt',
          'div',
          'ins',
          'del',
          'sup',
          'sub',
          'p',
          'ol',
          'ul',
          'table',
          'thead',
          'tbody',
          'tfoot',
          'blockquote',
          'dl',
          'dt',
          'dd',
          'kbd',
          'q',
          'samp',
          'var',
          'hr',
          'ruby',
          'rt',
          'rp',
          'li',
          'tr',
          'td',
          'th',
          's',
          'strike',
          'span',
          'abbr',
          'abbr',
          'summary',
        ],
        allowedAttributes: {
          '*': ['class', 'style'],
          a: ['href'],
          img: ['src'],
        },
      });
    },
  },
};
</script>

<template>
  <div class="cell text-cell">
    <prompt />
    <div class="markdown" v-html="markdown"></div>
  </div>
</template>

<style>
/*
  Importing the necessary katex stylesheet from the node_module folder rather
  than copying the stylesheet into `app/assets/stylesheets/vendors` for
  automatic importing via `app/assets/stylesheets/application.scss`. The reason
  is that the katex stylesheet depends on many fonts that are in node_module
  subfolders - moving all these fonts would make updating katex difficult.
 */
@import '~katex/dist/katex.min.css';

.markdown .katex {
  display: block;
  text-align: center;
}

.markdown .inline-katex .katex {
  display: inline;
  text-align: initial;
}
</style>
