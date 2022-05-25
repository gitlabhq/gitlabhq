import { isString } from 'lodash';
import { render } from '~/lib/gfm';
import { createProseMirrorDocFromMdastTree } from './hast_to_prosemirror_converter';

const factorySpecs = {
  blockquote: { type: 'block', selector: 'blockquote' },
  paragraph: { type: 'block', selector: 'p' },
  listItem: { type: 'block', selector: 'li', wrapTextInParagraph: true },
  orderedList: { type: 'block', selector: 'ol' },
  bulletList: { type: 'block', selector: 'ul' },
  heading: {
    type: 'block',
    selector: (hastNode) => ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(hastNode.tagName),
    getAttrs: (hastNode) => {
      const level = parseInt(/(\d)$/.exec(hastNode.tagName)?.[1], 10) || 1;

      return { level };
    },
  },
  codeBlock: {
    type: 'block',
    skipChildren: true,
    selector: 'pre',
    getContent: ({ hastNodeText }) => hastNodeText.replace(/\n$/, ''),
    getAttrs: (hastNode) => {
      const languageClass = hastNode.children[0]?.properties.className?.[0];
      const language = isString(languageClass) ? languageClass.replace('language-', '') : null;

      return { language };
    },
  },
  horizontalRule: {
    type: 'block',
    selector: 'hr',
  },
  image: {
    type: 'inline',
    selector: 'img',
    getAttrs: (hastNode) => ({
      src: hastNode.properties.src,
      title: hastNode.properties.title,
      alt: hastNode.properties.alt,
    }),
  },
  hardBreak: {
    type: 'inline',
    selector: 'br',
  },
  code: {
    type: 'mark',
    selector: 'code',
  },
  italic: {
    type: 'mark',
    selector: (hastNode) => ['em', 'i'].includes(hastNode.tagName),
  },
  bold: {
    type: 'mark',
    selector: (hastNode) => ['strong', 'b'].includes(hastNode.tagName),
  },
  link: {
    type: 'mark',
    selector: 'a',
    getAttrs: (hastNode) => ({
      href: hastNode.properties.href,
      title: hastNode.properties.title,
    }),
  },
  strike: {
    type: 'mark',
    selector: (hastNode) => ['strike', 's', 'del'].includes(hastNode.tagName),
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

      return { document };
    },
  };
};
