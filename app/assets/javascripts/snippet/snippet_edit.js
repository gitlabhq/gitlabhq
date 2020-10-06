import ZenMode from '~/zen_mode';
import { SnippetEditInit } from '~/snippets';

document.addEventListener('DOMContentLoaded', () => {
  SnippetEditInit();
  new ZenMode(); // eslint-disable-line no-new
});
