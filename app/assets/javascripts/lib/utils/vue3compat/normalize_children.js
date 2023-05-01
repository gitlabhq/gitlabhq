export function normalizeChildren(children) {
  if (typeof children !== 'object' || Array.isArray(children)) {
    return children;
  }

  if (typeof children.default === 'function') {
    return children.default();
  }

  return children;
}
