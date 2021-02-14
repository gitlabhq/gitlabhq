/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Code as BaseCode } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Code extends BaseCode {
  get toMarkdown() {
    return defaultMarkdownSerializer.marks.code;
  }
}
