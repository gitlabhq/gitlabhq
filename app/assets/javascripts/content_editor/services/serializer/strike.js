import { openTag, closeTag, preserveUnchangedMark } from '../serialization_helpers';

const generateStrikeTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    if (mark.attrs.sourceMarkdown) return '~~';
    if (mark.attrs.sourceTagName) return wrapTagName(mark.attrs.sourceTagName);
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    return '~~';
  };
};

const strike = preserveUnchangedMark({
  open: generateStrikeTag(),
  close: generateStrikeTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
});

export default strike;
