import { openTag, closeTag } from '../serialization_helpers';

const generateItalicTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    return '_';
  };
};

const italic = {
  open: generateItalicTag(),
  close: generateItalicTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default italic;
