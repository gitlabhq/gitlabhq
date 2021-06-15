import { buildTextToken, buildUneditableInlineTokens } from './build_uneditable_token';

/*
Use case examples:
- Majority: two bracket pairs, back-to-back, each with content (including spaces)
  - `[environment terraform plans][terraform]`
  - `[an issue labelled `~"main:broken"`][broken-main-issues]`
- Minority: two bracket pairs the latter being empty or only one pair with content (including spaces)
  - `[this link][]`
  - `[this link]`

Regexp notes:
  - `(?:\[.+?\]){1}`: Always one bracket pair with content (including spaces)
  - `(?:\[\]|\[.+?\])?`: Optional second pair that may or may not contain content (including spaces)
  - `(?!:)`: Never followed by a `:` which is reserved for identifier definition syntax (`[identifier]: /the-link`)
  - Each of the three parts is non-captured, but the match as a whole is captured
*/
const identifierInstanceRegex = /((?:\[.+?\]){1}(?:\[\]|\[.+?\])?(?!:))/g;

const isIdentifierInstance = (literal) => {
  // Reset lastIndex as global flag in regexp are stateful (https://stackoverflow.com/a/11477448)
  identifierInstanceRegex.lastIndex = 0;
  return identifierInstanceRegex.test(literal);
};

const canRender = ({ literal }) => isIdentifierInstance(literal);

const tokenize = (text) => {
  const matches = text.split(identifierInstanceRegex);
  const tokens = matches.map((match) => {
    const token = buildTextToken(match);
    return isIdentifierInstance(match) ? buildUneditableInlineTokens(token) : token;
  });

  return tokens.flat();
};

const render = (_, { origin }) => tokenize(origin().content);

export default { canRender, render };
