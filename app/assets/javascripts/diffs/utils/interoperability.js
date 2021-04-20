const OLD = 'old';
const NEW = 'new';
const ATTR_PREFIX = 'data-interop-';

export const ATTR_TYPE = `${ATTR_PREFIX}type`;
export const ATTR_LINE = `${ATTR_PREFIX}line`;
export const ATTR_NEW_LINE = `${ATTR_PREFIX}new-line`;
export const ATTR_OLD_LINE = `${ATTR_PREFIX}old-line`;

export const getInteropInlineAttributes = (line) => {
  if (!line) {
    return null;
  }

  const interopType = line.type?.startsWith(OLD) ? OLD : NEW;

  const interopLine = interopType === OLD ? line.old_line : line.new_line;

  return {
    [ATTR_TYPE]: interopType,
    [ATTR_LINE]: interopLine,
    [ATTR_NEW_LINE]: line.new_line,
    [ATTR_OLD_LINE]: line.old_line,
  };
};

export const getInteropOldSideAttributes = (line) => {
  if (!line) {
    return null;
  }

  return {
    [ATTR_TYPE]: OLD,
    [ATTR_LINE]: line.old_line,
    [ATTR_OLD_LINE]: line.old_line,
  };
};

export const getInteropNewSideAttributes = (line) => {
  if (!line) {
    return null;
  }

  return {
    [ATTR_TYPE]: NEW,
    [ATTR_LINE]: line.new_line,
    [ATTR_NEW_LINE]: line.new_line,
  };
};
