/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { BulletList as BaseBulletList } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class BulletList extends BaseBulletList {
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.bullet_list(state, node);
  }
}
