export const wrapLines = (content, language) => {
  const isValidLanguage = /^[a-z\d\-_]+$/.test(language); // To prevent the possibility of a vulnerability we only allow languages that contain alphanumeric characters ([a-z\d), dashes (-) or underscores (_).

  return (
    content &&
    content
      .split('\n')
      .map((line, i) => {
        let formattedLine;
        const attributes = `id="LC${i + 1}" lang="${isValidLanguage ? language : ''}"`;

        if (line.includes('<span class="hljs') && !line.includes('</span>')) {
          /**
           * In some cases highlight.js will wrap multiple lines in a span, in these cases we want to append the line number to the existing span
           *
           * example (before):  <span class="hljs-code">```bash
           * example (after):   <span id="LC67" class="hljs-code">```bash
           */
          formattedLine = line.replace(/(?=class="hljs)/, `${attributes} `);
        } else {
          formattedLine = `<span ${attributes} class="line">${line}</span>`;
        }

        return formattedLine;
      })
      .join('\n')
  );
};
