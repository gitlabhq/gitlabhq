import { renderUneditableLeaf as render } from './render_utils';

const kramdownRegex = /(^{:.+}$)/;

const canRender = ({ literal }) => {
  return kramdownRegex.test(literal);
};

export default { canRender, render };
