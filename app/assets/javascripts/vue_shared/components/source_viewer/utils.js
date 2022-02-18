export const wrapLines = (content) => {
  return (
    content &&
    content
      .split('\n')
      .map((line, i) => {
        let formattedLine;
        const idAttribute = `id="LC${i + 1}"`;

        if (line.includes('<span class="hljs') && !line.includes('</span>')) {
          /**
           * In some cases highlight.js will wrap multiple lines in a span, in these cases we want to append the line number to the existing span
           *
           * example (before):  <span class="hljs-code">```bash
           * example (after):   <span id="LC67" class="hljs-code">```bash
           */
          formattedLine = line.replace(/(?=class="hljs)/, `${idAttribute} `);
        } else {
          formattedLine = `<span ${idAttribute} class="line">${line}</span>`;
        }

        return formattedLine;
      })
      .join('\n')
  );
};
