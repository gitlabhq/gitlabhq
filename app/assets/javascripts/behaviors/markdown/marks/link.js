/* eslint-disable class-methods-use-this */

import { Link as BaseLink } from 'tiptap-extensions';
import { defaultMarkdownSerializer } from 'prosemirror-markdown';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Link extends BaseLink {
  get toMarkdown() {
    return {
      mixable: true,
      open(state, mark, parent, index) {
        const open = defaultMarkdownSerializer.marks.link.open(state, mark, parent, index);
        return open === '<' ? '' : open;
      },
      close(state, mark, parent, index) {
        const close = defaultMarkdownSerializer.marks.link.close(state, mark, parent, index);
        return close === '>' ? '' : close;
      },
    };
  }
}
