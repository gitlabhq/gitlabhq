import { buildUneditableOpenTokens, buildUneditableCloseToken } from './build_uneditable_token';

const isKramdownTOC = ({ type, literal }) => type === 'text' && literal === 'TOC';

const canRender = node => {
  let targetNode = node;
  while (targetNode !== null) {
    const { firstChild } = targetNode;
    const isLeaf = firstChild === null;
    if (isLeaf) {
      if (isKramdownTOC(targetNode)) {
        return true;
      }

      break;
    }

    targetNode = targetNode.firstChild;
  }

  return false;
};

const render = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();

export default { canRender, render };
