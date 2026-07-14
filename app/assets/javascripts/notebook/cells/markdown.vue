<script>
import katex from 'katex';
import { marked } from 'marked';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sanitize } from '~/lib/dompurify';
import { hasContent, markdownConfig } from '~/lib/utils/text_utility';
import Prompt from './prompt.vue';

const baseRenderer = new marked.Renderer();

// Per-render state set from the component's computed property before each parse call.
let currentAttachments = null;
let currentRelativeRawPath = '';

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

function deHTMLify(t) {
  // get some specific characters back, that are allowed for KaTex rendering
  const text = t.replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
  return text;
}
function renderKatex(t) {
  let text = t;
  let numInline = 0; // number of successful converted math formulas

  if (typeof katex !== 'undefined') {
    const katexString = text
      .replace(/&amp;/g, '&')
      .replace(/&=&/g, '\\space=\\space') // eslint-disable-line @gitlab/require-i18n-strings
      .replace(/<(\/?)em>/g, '_');
    const regex = new RegExp(katexRegexString, 'gi');
    const matchLocation = katexString.search(regex);
    const numberOfMatches = katexString.match(regex);

    if (numberOfMatches && numberOfMatches.length !== 0) {
      let matches = regex.exec(katexString);
      if (matchLocation > 0) {
        numInline += 1;

        while (matches !== null) {
          try {
            const renderedKatex = katex.renderToString(deHTMLify(matches[0].replace(/\$/g, '')));
            text = `${text.replace(matches[0], ` ${renderedKatex}`)}`;
          } catch {
            numInline -= 1;
          }
          matches = regex.exec(katexString);
        }
      } else {
        try {
          text = katex.renderToString(deHTMLify(matches[2]));
        } catch (error) {
          numInline -= 1;
        }
      }
    }
  }
  return [text, numInline > 0];
}
marked.use({
  renderer: {
    paragraph(t) {
      const rendered = this.parser.parseInline(t.tokens);
      const [text, inline] = renderKatex(rendered);
      return `<p class="${inline ? 'inline-katex' : ''}">${text}</p>`;
    },
    listitem(t) {
      const rendered = this.parser.parse(t.tokens, Boolean(t.loose));
      const [text, inline] = renderKatex(rendered);
      return `<li class="${inline ? 'inline-katex' : ''}">${text}</li>`;
    },
    image(token) {
      const { href } = token;
      const attachmentHeader = `attachment:`; // eslint-disable-line @gitlab/require-i18n-strings

      if (!currentAttachments || !href.startsWith(attachmentHeader)) {
        let relativeHref = href;

        // eslint-disable-next-line @gitlab/require-i18n-strings
        if (!(href.startsWith('http') || href.startsWith('data:'))) {
          // These are images within the repo. This will only work if the image
          // is relative to the path where the file is located
          relativeHref = currentRelativeRawPath + href;
        }

        return baseRenderer.image.call(this, { ...token, href: relativeHref });
      }

      let img = ``;
      const filename = href.substring(attachmentHeader.length);

      if (hasContent(filename)) {
        const attachment = currentAttachments[filename];

        if (attachment) {
          const imageType = Object.keys(attachment)[0];

          if (hasContent(imageType)) {
            const data = attachment[imageType];
            const inlined = `data:${imageType};base64,${data}"`; // eslint-disable-line @gitlab/require-i18n-strings
            img = baseRenderer.image.call(this, { ...token, href: inlined });
          }
        }
      }

      if (!hasContent(img)) {
        return baseRenderer.image.call(this, token);
      }

      return sanitize(img);
    },
  },
});

export default {
  name: 'NotebookMarkdown',
  components: {
    Prompt,
  },
  directives: {
    SafeHtml,
  },
  inject: ['relativeRawPath'],
  props: {
    cell: {
      type: Object,
      required: true,
    },
    hidePrompt: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    markdown() {
      currentAttachments = this.cell.attachments;
      currentRelativeRawPath = this.relativeRawPath;

      let { source } = this.cell;

      if (Array.isArray(source)) {
        source = source.join('');
      }

      return marked(source.replace(/\\/g, '\\\\'));
    },
  },
  markdownConfig,
};
</script>

<template>
  <div class="cell text-cell">
    <prompt v-if="!hidePrompt" />
    <div v-safe-html:[$options.markdownConfig]="markdown" class="markdown"></div>
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
