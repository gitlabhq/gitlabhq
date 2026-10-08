import { highlight } from './highlight_utils';

/**
 * A webworker for highlighting large amounts of content with Highlight.js
 */
self.addEventListener('message', async ({ data: { fileType, content, language } }) => {
  self.postMessage(await highlight(fileType, content, language));
});
