const path = require('path');

module.exports = {
  names: ['Custom rule/unnecessary-traversal'],
  description: 'Links should not traverse out and back into the same directory',
  tags: ['gitlab-docs', 'links'],
  function: (params, onError) => {
    // Get the current file directory name
    const { name: filePath = '', lines = [] } = params;
    const dirName = path.basename(path.dirname(filePath));

    if (!filePath) return;
    // Process each line
    lines.forEach((line, i) => {
      // Skip lines that don't contain markdown links with relative paths
      if (!line.includes('](../')) return;

      // Regular expression to find markdown links with potential traversal issues
      const linkRegex = /\[([^\]]+)\]\((\.\.\/([^/]+)\/)(.*?)(?:\s+"[^"]*")?\)/g;

      let match;
      while ((match = linkRegex.exec(line)) !== null) {
        /* 
          Destructure regex match into:
          - fullMatch: the entire link
          - linkText: the link text
          - traversalPart: the '../dir/' part
          - traversalDir: just the 'dir' part
          - targetPath: the rest of the path
        */
        const [fullMatch, linkText, traversalPart, traversalDir, targetPath] = match;

        // Check if traversal directory matches current directory
        if (traversalDir === dirName) {
          // Calculate positions for precise highlighting
          const linkStart = match.index;
          const traversalStart = fullMatch.indexOf(traversalPart);

          onError({
            lineNumber: i + 1,
            range: [linkStart + traversalStart, traversalPart.length],
            detail: `Link path does not need: '../${traversalDir}/'. Shorten link path to '[${linkText}](${targetPath})'`,
            fixInfo: {
              editColumn: linkStart + 1,
              deleteCount: fullMatch.length,
              insertText: `[${linkText}](${targetPath})`,
            },
          });
        }
      }
    });
  },
};
