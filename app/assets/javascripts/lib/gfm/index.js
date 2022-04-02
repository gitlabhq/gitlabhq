import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkRehype from 'remark-rehype';
import rehypeRaw from 'rehype-raw';

const createParser = () => {
  return unified().use(remarkParse).use(remarkRehype, { allowDangerousHtml: true }).use(rehypeRaw);
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
export const render = async ({ markdown, renderer }) => {
  const { value } = await createParser().use(compilerFactory(renderer)).process(markdown);

  return value;
};
