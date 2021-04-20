export const findInteropAttributes = (parent, sel) => {
  const target = sel ? parent.find(sel) : parent;

  if (!target.exists()) {
    return null;
  }

  const type = target.attributes('data-interop-type');

  if (!type) {
    return null;
  }

  return {
    type,
    line: target.attributes('data-interop-line'),
    oldLine: target.attributes('data-interop-old-line'),
    newLine: target.attributes('data-interop-new-line'),
  };
};
