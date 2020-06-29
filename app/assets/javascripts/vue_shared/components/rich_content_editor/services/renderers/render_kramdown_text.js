import { buildUneditableTokens } from './build_uneditable_token';

const kramdownRegex = /(^{:.+}$)/;

const canRender = ({ literal }) => {
  return kramdownRegex.test(literal);
};

const render = (_, { origin }) => {
  return buildUneditableTokens(origin());
};

export default { canRender, render };
