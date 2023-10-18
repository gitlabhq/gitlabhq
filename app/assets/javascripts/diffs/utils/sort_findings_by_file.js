export function sortFindingsByFile(newErrors = []) {
  const files = {};
  newErrors.forEach(({ filePath, line, description, severity }) => {
    if (!files[filePath]) {
      files[filePath] = [];
    }
    files[filePath].push({ line, description, severity: severity.toLowerCase() });
  });

  const sortedFiles = Object.keys(files)
    .sort()
    .reduce((acc, key) => {
      acc[key] = files[key];
      return acc;
    }, {});
  return { files: sortedFiles };
}
