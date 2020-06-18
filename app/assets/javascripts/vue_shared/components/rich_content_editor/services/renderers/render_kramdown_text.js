import { buildUneditableTokens } from './build_uneditable_token';

const canRender = ({ literal }) => {
  const kramdownRegex = /(^{:.+}$)/gm;
  return kramdownRegex.test(literal);
};

const render = ({ origin }) => {
  return buildUneditableTokens(origin());
};

export default { canRender, render };
