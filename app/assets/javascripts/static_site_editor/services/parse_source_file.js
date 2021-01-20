import { frontMatterify, stringify } from './front_matterify';

const parseSourceFile = (raw) => {
  let editable;

  const syncContent = (newVal, isBody) => {
    if (isBody) {
      editable.content = newVal;
    } else {
      try {
        editable = frontMatterify(newVal);
        editable.isMatterValid = true;
      } catch (e) {
        editable.isMatterValid = false;
      }
    }
  };

  const content = (isBody = false) => (isBody ? editable.content : stringify(editable));

  const matter = () => editable.matter;

  const syncMatter = (settings) => {
    editable.matter = settings;
  };

  const isModified = () => stringify(editable) !== raw;

  const hasMatter = () => editable.hasMatter;

  const isMatterValid = () => editable.isMatterValid;

  syncContent(raw);

  return {
    matter,
    isMatterValid,
    syncMatter,
    content,
    syncContent,
    isModified,
    hasMatter,
  };
};

export default parseSourceFile;
