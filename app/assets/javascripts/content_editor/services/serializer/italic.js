import { openTag, closeTag, preserveUnchangedMark } from '../serialization_helpers';

const generateItalicTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*|_).*/.exec(mark.attrs.sourceMarkdown)?.[1];
    if (type === '*' || type === '_') return type;

    if (mark.attrs.sourceTagName) return wrapTagName(mark.attrs.sourceTagName);

    return '_';
  };
};

const italic = preserveUnchangedMark({
  open: generateItalicTag(),
  close: generateItalicTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
});

export default italic;
