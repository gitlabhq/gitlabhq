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

  marked.setOptions({
    sanitize: true,
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
        const regex = new RegExp('^\\$\\$(.*)\\$\\$$', 'g');

        const source = this.cell.source.map((line) => {
          const matches = regex.exec(line.trim());

          // Only render use the Katex library if it is actually loaded
          if (matches && matches.length > 0 && typeof katex !== 'undefined') {
            return katex.renderToString(matches[1]);
          }

          return line;
        });

        return marked(source.join(''));
      },
    },
  };
</script>

<style>
.markdown .katex {
  display: block;
  text-align: center;
}
</style>
