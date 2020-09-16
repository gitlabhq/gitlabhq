import grayMatter from 'gray-matter';

const parseSourceFile = raw => {
  const remake = source => grayMatter(source, {});

  let editable = remake(raw);

  const syncContent = (newVal, isBody) => {
    if (isBody) {
      editable.content = newVal;
    } else {
      editable = remake(newVal);
    }
  };

  const trimmedEditable = () => grayMatter.stringify(editable).trim();

  const content = (isBody = false) => (isBody ? editable.content.trim() : trimmedEditable()); // gray-matter internally adds an eof newline so we trim to bypass, open issue: https://github.com/jonschlinkert/gray-matter/issues/96

  const matter = () => editable.data;

  const syncMatter = settings => {
    const source = grayMatter.stringify(editable.content, settings);
    syncContent(source);
  };

  const isModified = () => trimmedEditable() !== raw;

  const hasMatter = () => editable.matter.length > 0;

  return {
    matter,
    syncMatter,
    content,
    syncContent,
    isModified,
    hasMatter,
  };
};

export default parseSourceFile;
