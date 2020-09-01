import getFrontMatterLanguageDefinition from './parse_source_file_language_support';

const parseSourceFile = (raw, options = { frontMatterLanguage: 'yaml' }) => {
  const { open, close } = getFrontMatterLanguageDefinition(options.frontMatterLanguage);
  const anyChar = '[\\s\\S]';
  const frontMatterBlock = `^${open}$${anyChar}*?^${close}$`;
  const frontMatterRegex = new RegExp(`${frontMatterBlock}`, 'm');
  const preGroupedRegex = new RegExp(`(${anyChar}*?)(${frontMatterBlock})(\\s*)(${anyChar}*)`, 'm'); // preFrontMatter, frontMatter, spacing, and content
  let initial;
  let editable;

  const hasFrontMatter = source => frontMatterRegex.test(source);

  const buildPayload = (source, header, spacing, body) => {
    return { raw: source, header, spacing, body };
  };

  const parse = source => {
    if (hasFrontMatter(source)) {
      const match = source.match(preGroupedRegex);
      const [, preFrontMatter, frontMatter, spacing, content] = match;
      const header = preFrontMatter + frontMatter;

      return buildPayload(source, header, spacing, content);
    }

    return buildPayload(source, '', '', source);
  };

  const syncEditable = () => {
    /*
    We re-parse as markdown editing could have added non-body changes (preFrontMatter, frontMatter, or spacing).
    Re-parsing additionally gets us the desired body that was extracted from the potentially mutated editable.raw
    */
    editable = parse(editable.raw);
  };

  const refreshEditableRaw = () => {
    editable.raw = `${editable.header}${editable.spacing}${editable.body}`;
  };

  const sync = (newVal, isBodyToRaw) => {
    const editableKey = isBodyToRaw ? 'body' : 'raw';
    editable[editableKey] = newVal;

    if (isBodyToRaw) {
      refreshEditableRaw();
    }

    syncEditable();
  };

  const frontMatter = () => editable.header;

  const setFrontMatter = val => {
    editable.header = val;
    refreshEditableRaw();
  };

  const content = (isBody = false) => {
    const editableKey = isBody ? 'body' : 'raw';
    return editable[editableKey];
  };

  const isModified = () => initial.raw !== editable.raw;

  initial = parse(raw);
  editable = parse(raw);

  return {
    frontMatter,
    setFrontMatter,
    content,
    isModified,
    sync,
  };
};

export default parseSourceFile;
