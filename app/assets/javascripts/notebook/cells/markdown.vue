<script>
/* eslint-disable vue/no-v-html */
import katex from 'katex';
import marked from 'marked';
import { sanitize } from '~/lib/dompurify';
import { hasContent, markdownConfig } from '~/lib/utils/text_utility';
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

function deHTMLify(t) {
  // get some specific characters back, that are allowed for KaTex rendering
  const text = t.replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
  return text;
}
function renderKatex(t) {
  let text = t;
  let numInline = 0; // number of successfull converted math formulas

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
renderer.paragraph = (t) => {
  const [text, inline] = renderKatex(t);
  return `<p class="${inline ? 'inline-katex' : ''}">${text}</p>`;
};
renderer.listitem = (t) => {
  const [text, inline] = renderKatex(t);
  return `<li class="${inline ? 'inline-katex' : ''}">${text}</li>`;
};
renderer.originalImage = renderer.image;

renderer.image = function image(href, title, text) {
  const attachmentHeader = `attachment:`; // eslint-disable-line @gitlab/require-i18n-strings

  if (!this.attachments || !href.startsWith(attachmentHeader)) {
    return this.originalImage(href, title, text);
  }

  let img = ``;
  const filename = href.substring(attachmentHeader.length);

  if (hasContent(filename)) {
    const attachment = this.attachments[filename];

    if (attachment) {
      const imageType = Object.keys(attachment)[0];

      if (hasContent(imageType)) {
        const data = attachment[imageType];
        const inlined = `data:${imageType};base64,${data}"`; // eslint-disable-line @gitlab/require-i18n-strings
        img = this.originalImage(inlined, title, text);
      }
    }
  }

  if (!hasContent(img)) {
    return this.originalImage(href, title, text);
  }

  return sanitize(img);
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
      renderer.attachments = this.cell.attachments;

      return sanitize(marked(this.cell.source.join('').replace(/\\/g, '\\\\')), markdownConfig);
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
