/* eslint-disable class-methods-use-this */

import { BulletList as BaseBulletList } from 'tiptap-extensions';
import { defaultMarkdownSerializer } from 'prosemirror-markdown';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class BulletList extends BaseBulletList {
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.bullet_list(state, node);
  }
}
