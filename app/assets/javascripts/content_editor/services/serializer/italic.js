import { openTag, closeTag } from '../serialization_helpers';

const generateItalicTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*|_|<em|<i).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '*':
      case '_':
        return type;
      // eslint-disable-next-line @gitlab/require-i18n-strings
      case '<em':
      case '<i':
        return wrapTagName(type.substring(1));
      default:
        return '_';
    }
  };
};

const italic = {
  open: generateItalicTag(),
  close: generateItalicTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default italic;
