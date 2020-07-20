import { buildUneditableTokens } from './build_uneditable_token';

const embeddedRubyRegex = /(^<%.+%>$)/;

const canRender = ({ literal }) => {
  return embeddedRubyRegex.test(literal);
};

const render = (_, { origin }) => {
  return buildUneditableTokens(origin());
};

export default { canRender, render };
