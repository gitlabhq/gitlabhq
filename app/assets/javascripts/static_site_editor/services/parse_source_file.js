import { frontMatterify, stringify } from './front_matterify';

const parseSourceFile = raw => {
  const remake = source => frontMatterify(source);

  let editable = remake(raw);

  const syncContent = (newVal, isBody) => {
    if (isBody) {
      editable.content = newVal;
    } else {
      editable = remake(newVal);
    }
  };

  const content = (isBody = false) => (isBody ? editable.content : stringify(editable));

  const matter = () => editable.matter;

  const syncMatter = settings => {
    editable.matter = settings;
  };

  const isModified = () => stringify(editable) !== raw;

  const hasMatter = () => Boolean(editable.matter);

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
