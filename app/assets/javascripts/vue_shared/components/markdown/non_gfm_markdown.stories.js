import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';

export default {
  title: 'vue_shared/non_gfm_markdown',
  component: Markdown,
  parameters: {
    docs: {
      description: {
        component: `
This component is designed to render the markdown, which is **not** the GitLab Flavored Markdown.

It renders the code snippets the same way GitLab Flavored Markdown code snippets are rendered
respecting the user's preferred color scheme and featuring a copy-code button.

This component can be used to render client-side markdown that doesn't have GitLab-specific markdown elements such as issue links.
`,
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { Markdown },
  props: Object.keys(argTypes),
  template: '<markdown v-bind="$props" />',
});

const textWithCodeblock = `
#### Here is the text with the code block.

\`\`\`javascript
function sayHi(name) {
    console.log('Hi ' + name || 'Mark');
}
\`\`\`

It *can* have **formatting** as well
`;

export const OneCodeBlock = Template.bind({});
OneCodeBlock.args = { markdown: textWithCodeblock };

const textWithMultipleCodeBlocks = `
#### Here is the text with the code block.

\`\`\`javascript
function sayHi(name) {
    console.log('Hi ' + name || 'Mark');
}
\`\`\`

Note that the copy buttons are appearing independently

\`\`\`yaml
stages:
  - build
  - test
  - deploy
\`\`\`
`;

export const MultipleCodeBlocks = Template.bind({});
MultipleCodeBlocks.args = { markdown: textWithMultipleCodeBlocks };

const textUndefinedLanguage = `
#### Here is the code block with no language provided.

\`\`\`
function sayHi(name) {
    console.log('Hi ' + name || 'Mark');
}
\`\`\`
`;

export const UndefinedLanguage = Template.bind({});
UndefinedLanguage.args = { markdown: textUndefinedLanguage };

const textCodeOneLiner = `
#### Here is the text with the one-liner code block.

Note that copy button rendering is ok.

\`\`\`javascript
const foo = 'bar';
\`\`\`
`;

export const CodeOneLiner = Template.bind({});
CodeOneLiner.args = { markdown: textCodeOneLiner };
