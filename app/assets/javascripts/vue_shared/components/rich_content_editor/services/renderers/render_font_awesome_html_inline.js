import { buildUneditableInlineTokens } from './build_uneditable_token';

const fontAwesomeRegexOpen = /<i class="fa.+>/;

const canRender = ({ literal }) => {
  return fontAwesomeRegexOpen.test(literal);
};

const render = (_, { origin }) => buildUneditableInlineTokens(origin());

export default { canRender, render };
