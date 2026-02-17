import { openTag, closeTag } from '../serialization_helpers';

const generateStrikeTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    return '~~';
  };
};

const strike = {
  open: generateStrikeTag(),
  close: generateStrikeTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default strike;
