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

  const matter = () => editable.matter;

  const syncMatter = newMatter => {
    const targetMatter = newMatter.replace(/---/gm, ''); // TODO dynamic delimiter removal vs. hard code
    const currentMatter = matter();
    const currentContent = content();
    const newSource = currentContent.replace(currentMatter, targetMatter);
    syncContent(newSource);
    editable.matter = newMatter;
  };

  const matterObject = () => editable.data;

  const syncMatterObject = obj => {
    editable.data = obj;
  };

  const isModified = () => trimmedEditable() !== raw;

  return {
    matter,
    syncMatter,
    matterObject,
    syncMatterObject,
    content,
    syncContent,
    isModified,
  };
};

export default parseSourceFile;
