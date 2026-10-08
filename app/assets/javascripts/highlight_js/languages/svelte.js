/*
Language: Svelte.js
Requires: xml, javascript, typescript, css, scss
Description: Components of Svelte Framework
*/

export default (hljs) => {
  return {
    subLanguage: 'xml',
    contains: [
      hljs.COMMENT('<!--', '-->', {
        relevance: 11,
      }),
      {
        begin: /^(\s*)(<script.*(lang="ts").*>)/gm,
        end: /^(\s*)(<\/script>)/gm,
        subLanguage: 'typescript',
        excludeBegin: true,
        excludeEnd: true,
        relevance: 20,
        contains: [
          // special svelte $ syntax
          {
            begin: /^(\s*)(\$:)/gm,
            end: /(\s*)/gm,
            className: 'keyword',
          },
        ],
      },
      {
        begin: /^(\s*)(<script(\s*context="module")?.*>)/gm,
        end: /^(\s*)(<\/script>)/gm,
        subLanguage: 'javascript',
        excludeBegin: true,
        excludeEnd: true,
        relevance: 15,
        contains: [
          // special svelte $ syntax
          {
            begin: /^(\s*)(\$:)/gm,
            end: /(\s*)/gm,
            className: 'keyword',
          },
        ],
      },
      {
        begin: /^(\s*)(<style.*(lang="scss"|type="text\/scss").*>)/gm,
        end: /^(\s*)(<\/style>)/gm,
        subLanguage: 'scss',
        excludeBegin: true,
        excludeEnd: true,
        relevance: 20,
      },
      {
        begin: /^(\s*)(<style.*>)/gm,
        end: /^(\s*)(<\/style>)/gm,
        subLanguage: 'css',
        excludeBegin: true,
        excludeEnd: true,
        relevance: 15,
      },
      {
        begin: /\{/gm,
        end: /}/gm,
        subLanguage: 'javascript',
        contains: [
          {
            begin: /[{]/,
            end: /[}]/,
            skip: true,
          },
          {
            begin: /([#:/@])(if|else|each|await|then|catch|debug|html)/gm,
            className: 'keyword',
            relevance: 10,
          },
        ],
      },
    ],
  };
};
