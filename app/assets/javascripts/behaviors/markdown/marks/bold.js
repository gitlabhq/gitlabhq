/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Bold as BaseBold } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Bold extends BaseBold {
  get toMarkdown() {
    return defaultMarkdownSerializer.marks.strong;
  }
}
