import { first, last } from 'lodash';
import { u } from 'unist-builder';
import { visitParents, SKIP, CONTINUE } from 'unist-util-visit-parents';
import {
  TABLE_OF_CONTENTS_DOUBLE_BRACKET_CLOSE_TOKEN,
  TABLE_OF_CONTENTS_DOUBLE_BRACKET_MIDDLE_TOKEN,
  TABLE_OF_CONTENTS_DOUBLE_BRACKET_OPEN_TOKEN,
  TABLE_OF_CONTENTS_SINGLE_BRACKET_TOKEN,
  MDAST_TEXT_NODE,
  MDAST_EMPHASIS_NODE,
  MDAST_PARAGRAPH_NODE,
  GLFM_TABLE_OF_CONTENTS_NODE,
} from '../constants';

const isTOCTextNode = ({ type, value }) =>
  type === MDAST_TEXT_NODE && value === TABLE_OF_CONTENTS_DOUBLE_BRACKET_MIDDLE_TOKEN;

const isTOCEmphasisNode = ({ type, children }) =>
  type === MDAST_EMPHASIS_NODE && children.length === 1 && isTOCTextNode(first(children));

const isTOCDoubleSquareBracketOpenTokenTextNode = ({ type, value }) =>
  type === MDAST_TEXT_NODE && value.trim() === TABLE_OF_CONTENTS_DOUBLE_BRACKET_OPEN_TOKEN;

const isTOCDoubleSquareBracketCloseTokenTextNode = ({ type, value }) =>
  type === MDAST_TEXT_NODE && value.trim() === TABLE_OF_CONTENTS_DOUBLE_BRACKET_CLOSE_TOKEN;

/*
 * Detects table of contents declaration with syntax [[_TOC_]]
 */
const isTableOfContentsDoubleSquareBracketSyntax = ({ children }) => {
  if (children.length !== 3) {
    return false;
  }

  const [firstChild, middleChild, lastChild] = children;

  return (
    isTOCDoubleSquareBracketOpenTokenTextNode(firstChild) &&
    isTOCEmphasisNode(middleChild) &&
    isTOCDoubleSquareBracketCloseTokenTextNode(lastChild)
  );
};

/*
 * Detects table of contents declaration with syntax [TOC]
 */
const isTableOfContentsSingleSquareBracketSyntax = ({ children }) => {
  if (children.length !== 1) {
    return false;
  }

  const [firstChild] = children;
  const { type, value } = firstChild;

  return type === MDAST_TEXT_NODE && value.trim() === TABLE_OF_CONTENTS_SINGLE_BRACKET_TOKEN;
};

const isTableOfContentsNode = (node) =>
  node.type === MDAST_PARAGRAPH_NODE &&
  (isTableOfContentsDoubleSquareBracketSyntax(node) ||
    isTableOfContentsSingleSquareBracketSyntax(node));

export default () => {
  return (tree) => {
    visitParents(tree, (node, ancestors) => {
      const parent = last(ancestors);

      if (!parent) {
        return CONTINUE;
      }

      if (isTableOfContentsNode(node)) {
        const index = parent.children.indexOf(node);

        parent.children[index] = u(GLFM_TABLE_OF_CONTENTS_NODE, {
          position: node.position,
        });
      }

      return SKIP;
    });

    return tree;
  };
};
