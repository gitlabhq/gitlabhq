import { render } from '~/lib/gfm';
import { isValidAttribute } from '~/lib/dompurify';
import { SAFE_AUDIO_EXT, SAFE_VIDEO_EXT, DIAGRAM_LANGUAGES } from '../constants';
import { createProseMirrorDocFromMdastTree } from './hast_to_prosemirror_converter';

const ALL_AUDIO_VIDEO_EXT = [...SAFE_AUDIO_EXT, ...SAFE_VIDEO_EXT];

const wrappableTags = ['img', 'br', 'code', 'i', 'em', 'b', 'strong', 'a', 'strike', 's', 'del'];

const isTaskItem = (hastNode) => {
  const className = hastNode.properties?.className;

  return (
    hastNode.tagName === 'li' && Array.isArray(className) && className.includes('task-list-item')
  );
};

const getTableCellAttrs = (hastNode) => ({
  colspan: parseInt(hastNode.properties.colSpan, 10) || 1,
  rowspan: parseInt(hastNode.properties.rowSpan, 10) || 1,
});

const getMediaAttrs = (hastNode) => ({
  src: hastNode.properties.src,
  canonicalSrc: hastNode.properties.identifier ?? hastNode.properties.src,
  isReference: hastNode.properties.isReference === 'true',
  title: hastNode.properties.title,
  alt: hastNode.properties.alt,
});

const isMediaTag = (hastNode) => hastNode.tagName === 'img' && Boolean(hastNode.properties);

const extractMediaFileExtension = (url) => {
  try {
    const parsedUrl = new URL(url, window.location.origin);

    return /\.(\w+)$/.exec(parsedUrl.pathname)?.[1] ?? null;
  } catch {
    return null;
  }
};

const isCodeBlock = (hastNode) => hastNode.tagName === 'codeblock';

const isDiagramCodeBlock = (hastNode) => DIAGRAM_LANGUAGES.includes(hastNode.properties?.language);

const getCodeBlockAttrs = (hastNode) => ({ language: hastNode.properties.language });

const factorySpecs = {
  blockquote: { type: 'block', selector: 'blockquote' },
  paragraph: { type: 'block', selector: 'p' },
  listItem: {
    type: 'block',
    wrapInParagraph: true,
    selector: (hastNode) => hastNode.tagName === 'li' && !hastNode.properties?.className,
    processText: (text) => text.trimRight(),
  },
  orderedList: {
    type: 'block',
    selector: (hastNode) => hastNode.tagName === 'ol' && !hastNode.properties?.className,
  },
  bulletList: {
    type: 'block',
    selector: (hastNode) => hastNode.tagName === 'ul' && !hastNode.properties?.className,
  },
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
    selector: (hastNode) => isCodeBlock(hastNode) && !isDiagramCodeBlock(hastNode),
    getAttrs: getCodeBlockAttrs,
  },
  diagram: {
    type: 'block',
    selector: (hastNode) => isCodeBlock(hastNode) && isDiagramCodeBlock(hastNode),
    getAttrs: getCodeBlockAttrs,
  },
  horizontalRule: {
    type: 'block',
    selector: 'hr',
  },
  taskList: {
    type: 'block',
    selector: (hastNode) => {
      const className = hastNode.properties?.className;

      return (
        ['ul', 'ol'].includes(hastNode.tagName) &&
        Array.isArray(className) &&
        className.includes('contains-task-list')
      );
    },
    getAttrs: (hastNode) => ({
      numeric: hastNode.tagName === 'ol',
    }),
  },
  taskItem: {
    type: 'block',
    wrapInParagraph: true,
    selector: isTaskItem,
    getAttrs: (hastNode) => ({
      checked: hastNode.children[0].properties.checked,
    }),
    processText: (text) => text.trimLeft(),
  },
  taskItemCheckbox: {
    type: 'ignore',
    selector: (hastNode, ancestors) =>
      hastNode.tagName === 'input' && isTaskItem(ancestors[ancestors.length - 1]),
  },
  div: {
    type: 'block',
    selector: 'div',
    wrapInParagraph: true,
  },
  table: {
    type: 'block',
    selector: 'table',
  },
  tableRow: {
    type: 'block',
    selector: 'tr',
    parent: 'table',
  },
  tableHeader: {
    type: 'block',
    selector: 'th',
    getAttrs: getTableCellAttrs,
    wrapInParagraph: true,
  },
  tableCell: {
    type: 'block',
    selector: 'td',
    getAttrs: getTableCellAttrs,
    wrapInParagraph: true,
  },
  ignoredTableNodes: {
    type: 'ignore',
    selector: (hastNode) => ['thead', 'tbody', 'tfoot'].includes(hastNode.tagName),
  },
  footnoteDefinition: {
    type: 'block',
    selector: 'footnotedefinition',
    getAttrs: (hastNode) => hastNode.properties,
  },
  pre: {
    type: 'block',
    selector: 'pre',
    wrapInParagraph: true,
  },
  audio: {
    type: 'inline',
    selector: (hastNode) =>
      isMediaTag(hastNode) &&
      SAFE_AUDIO_EXT.includes(extractMediaFileExtension(hastNode.properties.src)),
    getAttrs: getMediaAttrs,
  },
  image: {
    type: 'inline',
    selector: (hastNode) =>
      isMediaTag(hastNode) &&
      !ALL_AUDIO_VIDEO_EXT.includes(extractMediaFileExtension(hastNode.properties.src)),
    getAttrs: getMediaAttrs,
  },
  video: {
    type: 'inline',
    selector: (hastNode) =>
      isMediaTag(hastNode) &&
      SAFE_VIDEO_EXT.includes(extractMediaFileExtension(hastNode.properties.src)),
    getAttrs: getMediaAttrs,
  },
  hardBreak: {
    type: 'inline',
    selector: 'br',
  },
  footnoteReference: {
    type: 'inline',
    selector: 'footnotereference',
    getAttrs: (hastNode) => hastNode.properties,
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
      canonicalSrc: hastNode.properties.identifier ?? hastNode.properties.href,
      href: hastNode.properties.href,
      isReference: hastNode.properties.isReference === 'true',
      title: hastNode.properties.title,
    }),
  },
  strike: {
    type: 'mark',
    selector: (hastNode) => ['strike', 's', 'del'].includes(hastNode.tagName),
  },
  /* TODO
   * Implement proper editing support for HTML comments in the Content Editor
   * https://gitlab.com/gitlab-org/gitlab/-/issues/342173
   */
  comment: {
    type: 'ignore',
    selector: (hastNode) => hastNode.type === 'comment',
  },

  referenceDefinition: {
    type: 'block',
    selector: 'referencedefinition',
    getAttrs: (hastNode) => ({
      title: hastNode.properties.title,
      url: hastNode.properties.url,
      identifier: hastNode.properties.identifier,
    }),
  },

  frontmatter: {
    type: 'block',
    selector: 'frontmatter',
    getAttrs: (hastNode) => ({
      language: hastNode.properties.language,
    }),
  },

  tableOfContents: {
    type: 'block',
    selector: 'tableofcontents',
  },
};

const SANITIZE_ALLOWLIST = ['level', 'identifier', 'numeric', 'language', 'url', 'isReference'];

const sanitizeAttribute = (attributeName, attributeValue, hastNode) => {
  if (!attributeValue || SANITIZE_ALLOWLIST.includes(attributeName)) {
    return attributeValue;
  }

  /**
   * This is a workaround to validate the value of the canonicalSrc
   * attribute using DOMPurify without passing the attribute name. canonicalSrc
   * is not an allowed attribute in DOMPurify therefore the library will remove
   * it regardless of its value.
   *
   * We want to preserve canonicalSrc, and we also want to make sure that its
   * value is sanitized.
   */
  const validateAttributeAs = attributeName === 'canonicalSrc' ? 'src' : attributeName;

  if (!isValidAttribute(hastNode.tagName, validateAttributeAs, attributeValue)) {
    return null;
  }

  return attributeValue;
};

const attributeTransformer = {
  transform: (attributeName, attributeValue, hastNode) => {
    return sanitizeAttribute(attributeName, attributeValue, hastNode);
  },
};

export default () => {
  return {
    deserialize: async ({ schema, markdown }) => {
      const document = await render({
        markdown,
        renderer: (tree) =>
          createProseMirrorDocFromMdastTree({
            schema,
            factorySpecs,
            tree,
            wrappableTags,
            attributeTransformer,
            markdown,
          }),
        skipRendering: [
          'footnoteReference',
          'footnoteDefinition',
          'code',
          'definition',
          'linkReference',
          'imageReference',
          'yaml',
          'toml',
          'json',
          'tableOfContents',
        ],
      });

      return { document };
    },
  };
};
