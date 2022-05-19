import { memoize } from 'lodash';

export default ({ renderMarkdown }) => ({
  resolveUrl: memoize(async (canonicalSrc) => {
    const html = await renderMarkdown(`[link](${canonicalSrc})`);
    if (!html) return canonicalSrc;

    const parser = new DOMParser();
    const { body } = parser.parseFromString(html, 'text/html');

    return body.querySelector('a').getAttribute('href');
  }),
});
