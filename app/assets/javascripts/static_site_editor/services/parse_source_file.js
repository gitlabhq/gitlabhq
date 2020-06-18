const parseSourceFile = raw => {
  const frontMatterRegex = /(^---$[\s\S]*?^---$)/m;
  const preGroupedRegex = /([\s\S]*?)(^---$[\s\S]*?^---$)(\s*)([\s\S]*)/m; // preFrontMatter, frontMatter, spacing, and content
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

  const computedRaw = () => `${editable.header}${editable.spacing}${editable.body}`;

  const syncBody = () => {
    /*
    We re-parse as markdown editing could have added non-body changes (preFrontMatter, frontMatter, or spacing).
    Re-parsing additionally gets us the desired body that was extracted from the mutated editable.raw
    Additionally we intentionally mutate the existing editable's key values as opposed to reassigning the object itself so consumers of the potentially reactive property stay in sync.
    */
    Object.assign(editable, parse(editable.raw));
  };

  const syncRaw = () => {
    editable.raw = computedRaw();
  };

  const isModifiedRaw = () => initial.raw !== editable.raw;
  const isModifiedBody = () => initial.raw !== computedRaw();

  initial = parse(raw);
  editable = parse(raw);

  return {
    editable,
    isModifiedRaw,
    isModifiedBody,
    syncRaw,
    syncBody,
  };
};

export default parseSourceFile;
