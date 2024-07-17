import { openTag, closeTag } from '../serialization_helpers';

const generateStrikeTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    const type = /^(~~|<del|<strike|<s).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '~~':
        return type;
      case '<del': // eslint-disable-line @gitlab/require-i18n-strings
      case '<strike': // eslint-disable-line @gitlab/require-i18n-strings
      case '<s':
        return wrapTagName(type.substring(1));
      default:
        return '~~';
    }
  };
};

const strike = {
  open: generateStrikeTag(),
  close: generateStrikeTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default strike;
