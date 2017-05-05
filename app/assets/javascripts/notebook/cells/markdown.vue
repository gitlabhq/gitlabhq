<template>
  <div class="cell text-cell">
    <prompt />
    <div class="markdown" v-html="markdown"></div>
  </div>
</template>

<script>
  /* global katex */
  import marked from 'marked';
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
    (.+?)
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
      const katexString = text.replace(/\\/g, '\\');
      const matches = new RegExp(katexRegexString, 'gi').exec(katexString);

      if (matches && matches.length > 0) {
        if (matches[1].trim() === '$' && matches[3].trim() === '$') {
          inline = true;

          text = `${katexString.replace(matches[0], '')} ${katex.renderToString(matches[2])}`;
        } else {
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
        return marked(this.cell.source.join(''));
      },
    },
  };
</script>

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
