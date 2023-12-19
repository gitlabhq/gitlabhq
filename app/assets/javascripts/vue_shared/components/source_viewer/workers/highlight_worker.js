import { highlight } from './highlight_utils';

/**
 * A webworker for highlighting large amounts of content with Highlight.js
 */
// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', async ({ data: { fileType, content, language } }) => {
  // eslint-disable-next-line no-restricted-globals
  self.postMessage(await highlight(fileType, content, language));
});
