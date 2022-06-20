import { memoize } from 'lodash';

const parser = new DOMParser();

export default ({ renderMarkdown }) => ({
  resolveUrl: memoize(async (canonicalSrc) => {
    const html = await renderMarkdown(`[link](${canonicalSrc})`);
    if (!html) return canonicalSrc;

    const { body } = parser.parseFromString(html, 'text/html');
    return body.querySelector('a').getAttribute('href');
  }),

  renderDiagram: memoize(async (code, language) => {
    const backticks = '`'.repeat(4);
    const html = await renderMarkdown(`${backticks}${language}\n${code}\n${backticks}`);

    const { body } = parser.parseFromString(html, 'text/html');
    const img = body.querySelector('img');
    if (!img) return '';

    return img.dataset.src || img.getAttribute('src');
  }),
});
