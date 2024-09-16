import { openTag, closeTag, getMarkText } from '../serialization_helpers';

const generateCodeTag = (wrapTagName = openTag) => {
  const isOpen = wrapTagName === openTag;

  return (_, mark, parent) => {
    const { sourceTagName, sourceMarkdown } = mark.attrs;
    if (sourceTagName && !sourceMarkdown) return wrapTagName(mark.attrs.sourceTagName);

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
};

export default code;
