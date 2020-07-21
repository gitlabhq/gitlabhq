import { renderUneditableBranch as render } from './render_utils';

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

export default { canRender, render };
