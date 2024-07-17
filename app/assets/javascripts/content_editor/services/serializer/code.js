import { openTag, closeTag, getMarkText } from '../serialization_helpers';

const generateCodeTag = (wrapTagName = openTag) => {
  const isOpen = wrapTagName === openTag;

  return (_, mark, parent) => {
    const type = /^(`|<code).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    if (type === '<code') {
      return wrapTagName(type.substring(1));
    }

    const childText = getMarkText(mark, parent);
    if (childText.includes('`')) {
      let tag = '``';
      if (childText.startsWith('`') || childText.endsWith('`'))
        tag = isOpen ? `${tag} ` : ` ${tag}`;
      return tag;
    }

    return '`';
  };
};

const code = {
  open: generateCodeTag(),
  close: generateCodeTag(closeTag),
  mixable: true,
  escape: false,
  expelEnclosingWhitespace: true,
};

export default code;
