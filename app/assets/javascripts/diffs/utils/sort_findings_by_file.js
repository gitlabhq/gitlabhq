export function sortFindingsByFile(newErrors = []) {
  const files = {};
  newErrors.forEach(({ line, description, severity, filePath, webUrl, engineName }) => {
    if (!files[filePath]) {
      files[filePath] = [];
    }
    files[filePath].push({
      line,
      description,
      severity: severity.toLowerCase(),
      filePath,
      webUrl,
      engineName,
    });
  });

  const sortedFiles = Object.keys(files)
    .sort()
    .reduce((acc, key) => {
      acc[key] = files[key];
      return acc;
    }, {});
  return { files: sortedFiles };
}
