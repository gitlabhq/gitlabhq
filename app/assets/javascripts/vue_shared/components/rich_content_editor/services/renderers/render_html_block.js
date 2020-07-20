import { buildUneditableHtmlAsTextTokens } from './build_uneditable_token';

const canRender = ({ type }) => {
  return type === 'htmlBlock';
};

const render = node => buildUneditableHtmlAsTextTokens(node);

export default { canRender, render };
