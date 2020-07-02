import {
  buildUneditableOpenTokens,
  buildUneditableCloseTokens,
  buildUneditableTokens,
} from './build_uneditable_token';

const identifierRegex = /(^\[.+\]: .+)/;

const isBasicIdentifier = ({ literal }) => {
  return identifierRegex.test(literal);
};

const isInlineCodeNode = ({ type, tickCount }) => type === 'code' && tickCount === 1;

const hasAdjacentInlineCode = (isForward, node) => {
  const direction = isForward ? 'next' : 'prev';

  let currentNode = node;
  while (currentNode[direction] && currentNode.literal !== null) {
    if (isInlineCodeNode(currentNode)) {
      return true;
    }

    currentNode = currentNode[direction];
  }

  return false;
};

const hasEnteringPotential = literal => literal.includes('[');
const hasExitingPotential = literal => literal.includes(']: ');

const hasAdjacentExit = node => {
  let currentNode = node;

  while (currentNode && currentNode.literal !== null) {
    if (hasExitingPotential(currentNode.literal)) {
      return true;
    }

    currentNode = currentNode.next;
  }

  return false;
};

const isEnteringWithAdjacentInlineCode = ({ literal, next }) => {
  if (next && hasEnteringPotential(literal) && !hasExitingPotential(literal)) {
    return hasAdjacentInlineCode(true, next) && hasAdjacentExit(next);
  }

  return false;
};

const isExitingWithAdjacentInlineCode = ({ literal, prev }) => {
  if (prev && !hasEnteringPotential(literal) && hasExitingPotential(literal)) {
    return hasAdjacentInlineCode(false, prev);
  }

  return false;
};

const isAdjacentInlineCodeIdentifier = node => {
  return isEnteringWithAdjacentInlineCode(node) || isExitingWithAdjacentInlineCode(node);
};

const canRender = (node, context) => {
  return isBasicIdentifier(node) || isAdjacentInlineCodeIdentifier(node, context);
};

const render = (node, { origin }) => {
  if (isEnteringWithAdjacentInlineCode(node)) {
    return buildUneditableOpenTokens(origin());
  } else if (isExitingWithAdjacentInlineCode(node)) {
    return buildUneditableCloseTokens(origin());
  }

  return buildUneditableTokens(origin());
};

export default { canRender, render };
