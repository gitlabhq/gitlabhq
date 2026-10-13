import { openTag, closeTag } from '../serialization_helpers';
import { recordDelimiter } from '../emphasis_delimiters';

const generateStrikeTag = (wrapTagName = openTag) => {
  return (state, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    return recordDelimiter(state, mark, '~~');
  };
};

const strike = {
  open: generateStrikeTag(),
  close: generateStrikeTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default strike;
