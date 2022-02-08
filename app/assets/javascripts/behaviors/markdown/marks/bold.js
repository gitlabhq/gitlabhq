/* eslint-disable class-methods-use-this */

import { Bold as BaseBold } from 'tiptap-extensions';
import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Bold extends BaseBold {
  get toMarkdown() {
    return defaultMarkdownSerializer.marks.strong;
  }
}
