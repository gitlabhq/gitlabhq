import { isString } from 'lodash';
import { render } from '~/lib/gfm';
import { createProseMirrorDocFromMdastTree } from './hast_to_prosemirror_converter';

const factorySpecs = {
  blockquote: { block: 'blockquote' },
  p: { block: 'paragraph' },
  li: { block: 'listItem', wrapTextInParagraph: true },
  ul: { block: 'bulletList' },
  ol: { block: 'orderedList' },
  h1: {
    block: 'heading',
    getAttrs: () => ({ level: 1 }),
  },
  h2: {
    block: 'heading',
    getAttrs: () => ({ level: 2 }),
  },
  h3: {
    block: 'heading',
    getAttrs: () => ({ level: 3 }),
  },
  h4: {
    block: 'heading',
    getAttrs: () => ({ level: 4 }),
  },
  h5: {
    block: 'heading',
    getAttrs: () => ({ level: 5 }),
  },
  h6: {
    block: 'heading',
    getAttrs: () => ({ level: 6 }),
  },
  pre: {
    block: 'codeBlock',
    skipChildren: true,
    getContent: ({ hastNodeText }) => hastNodeText,
    getAttrs: (hastNode) => {
      const languageClass = hastNode.children[0]?.properties.className?.[0];
      const language = isString(languageClass) ? languageClass.replace('language-', '') : '';

      return { language };
    },
  },
  hr: { inline: 'horizontalRule' },
  img: {
    inline: 'image',
    getAttrs: (hastNode) => ({
      src: hastNode.properties.src,
      title: hastNode.properties.title,
      alt: hastNode.properties.alt,
    }),
  },
  br: { inline: 'hardBreak' },
  code: { mark: 'code' },
  em: { mark: 'italic' },
  i: { mark: 'italic' },
  strong: { mark: 'bold' },
  b: { mark: 'bold' },
  a: {
    mark: 'link',
    getAttrs: (hastNode) => ({
      href: hastNode.properties.href,
      title: hastNode.properties.title,
    }),
  },
};

export default () => {
  return {
    deserialize: async ({ schema, content: markdown }) => {
      const document = await render({
        markdown,
        renderer: (tree) =>
          createProseMirrorDocFromMdastTree({
            schema,
            factorySpecs,
            tree,
            source: markdown,
          }),
      });

      return { document, languages: [] };
    },
  };
};
