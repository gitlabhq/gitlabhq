/* eslint-disable class-methods-use-this */

import { HardBreak as BaseHardBreak } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class HardBreak extends BaseHardBreak {
  toMarkdown(state) {
    if (!state.atBlank()) state.write('  \n');
  }
}
