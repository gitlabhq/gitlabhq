const REF_TYPES = ['heads', 'tags'];

export const getRefType = (refType) => {
  if (!refType) return null;

  const type = REF_TYPES.find((t) => t === refType?.toLowerCase());

  return type?.toUpperCase() || null;
};
