import { buildUneditableTokens } from './build_uneditable_token';

const canRender = ({ type }) => {
  return type === 'htmlBlock';
};

const render = (_, { origin }) => buildUneditableTokens(origin());

export default { canRender, render };
