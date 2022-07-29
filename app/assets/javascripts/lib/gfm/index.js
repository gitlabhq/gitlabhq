import { pick } from 'lodash';
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype, { all } from 'remark-rehype';
import rehypeRaw from 'rehype-raw';

const skipRenderingHandlers = {
  footnoteReference: (h, node) =>
    h(node.position, 'footnoteReference', { identifier: node.identifier, label: node.label }, []),
  footnoteDefinition: (h, node) =>
    h(
      node.position,
      'footnoteDefinition',
      { identifier: node.identifier, label: node.label },
      all(h, node),
    ),
  code: (h, node) =>
    h(node.position, 'codeBlock', { language: node.lang, meta: node.meta }, [
      { type: 'text', value: node.value },
    ]),
  definition: (h, node) => {
    const title = node.title ? ` "${node.title}"` : '';

    return h(
      node.position,
      'referenceDefinition',
      { identifier: node.identifier, url: node.url, title: node.title },
      [{ type: 'text', value: `[${node.identifier}]: ${node.url}${title}` }],
    );
  },
};

const createParser = ({ skipRendering = [] }) => {
  return unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype, {
      allowDangerousHtml: true,
      handlers: {
        ...pick(skipRenderingHandlers, skipRendering),
      },
    })
    .use(rehypeRaw);
};

const compilerFactory = (renderer) =>
  function compiler() {
    Object.assign(this, {
      Compiler(tree) {
        return renderer(tree);
      },
    });
  };

/**
 * Parses a Markdown string and provides the result Abstract
 * Syntax Tree (AST) to a renderer function to convert the
 * tree in any desired representation
 *
 * @param {String} params.markdown Markdown to parse
 * @param {(tree: MDast -> any)} params.renderer A function that accepts mdast
 * AST tree and returns an object of any type that represents the result of
 * rendering the tree. See the references below to for more information
 * about MDast.
 *
 * MDastTree documentation https://github.com/syntax-tree/mdast
 * @returns {Promise<any>} Returns a promise with the result of rendering
 * the MDast tree
 */
export const render = async ({ markdown, renderer, skipRendering = [] }) => {
  const { result } = await createParser({ skipRendering })
    .use(compilerFactory(renderer))
    .process(markdown);

  return result;
};
