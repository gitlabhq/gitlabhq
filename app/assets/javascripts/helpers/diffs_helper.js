export function hasInlineLines(diffFile) {
  return diffFile?.highlighted_diff_lines?.length > 0;
}

export function hasParallelLines(diffFile) {
  return diffFile?.parallel_diff_lines?.length > 0;
}

export function isSingleViewStyle(diffFile) {
  return !hasParallelLines(diffFile) || !hasInlineLines(diffFile);
}

export function hasDiff(diffFile) {
  return hasInlineLines(diffFile) || hasParallelLines(diffFile);
}
