import { openTag, closeTag } from '../serialization_helpers';

const generateBoldTags = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*\*|__|<strong|<b).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '**':
      case '__':
        return type;
      // eslint-disable-next-line @gitlab/require-i18n-strings
      case '<strong':
      case '<b':
        return wrapTagName(type.substring(1));
      default:
        return '**';
    }
  };
};

const bold = {
  open: generateBoldTags(),
  close: generateBoldTags(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

export default bold;
