export function hasInlineLines(diffFile) {
  return diffFile?.highlighted_diff_lines?.length > 0; /* eslint-disable-line camelcase */
}

export function hasParallelLines(diffFile) {
  return diffFile?.parallel_diff_lines?.length > 0; /* eslint-disable-line camelcase */
}

export function isSingleViewStyle(diffFile) {
  return !hasParallelLines(diffFile) || !hasInlineLines(diffFile);
}

export function hasDiff(diffFile) {
  return (
    hasInlineLines(diffFile) ||
    hasParallelLines(diffFile) ||
    !diffFile?.blob?.readable_text /* eslint-disable-line camelcase */
  );
}
