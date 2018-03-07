<script>
  /* global katex */
  import marked from 'marked';
  import sanitize from 'sanitize-html';
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
  `.replace(/\s/g, '').trim();

  renderer.paragraph = (t) => {
    let text = t;
    let inline = false;

    if (typeof katex !== 'undefined') {
      const katexString = text.replace(/&amp;/g, '&')
        .replace(/&=&/g, '\\space=\\space')
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
    sanitize: true,
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
          allowedTags: false,
          allowedAttributes: {
            '*': ['class'],
          },
        });
      },
    },
  };
</script>

<template>
  <div class="cell text-cell">
    <prompt />
    <div
      class="markdown"
      v-html="markdown">
    </div>
  </div>
</template>

<style>
  .markdown .katex {
    display: block;
    text-align: center;
  }

  .markdown .inline-katex .katex {
    display: inline;
    text-align: initial;
  }
</style>
