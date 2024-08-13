import { openTag, closeTag, preserveUnchangedMark } from '../serialization_helpers';

const generateBoldTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*\*|__).*/.exec(mark.attrs.sourceMarkdown)?.[1];
    if (type === '**' || type === '__') return type;
    if (mark.attrs.sourceTagName) return wrapTagName(mark.attrs.sourceTagName);

    return '**';
  };
};

const bold = preserveUnchangedMark({
  open: generateBoldTag(),
  close: generateBoldTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
});

export default bold;
