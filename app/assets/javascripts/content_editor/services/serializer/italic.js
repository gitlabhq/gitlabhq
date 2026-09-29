import { openTag, closeTag } from '../serialization_helpers';
import { recordDelimiter } from '../emphasis_delimiters';

const generateItalicTag = (wrapTagName = openTag) => {
  return (state, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    return recordDelimiter(state, mark, '_');
  };
};

const italic = {
  open: generateItalicTag(),
  close: generateItalicTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default italic;
