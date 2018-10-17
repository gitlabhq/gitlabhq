import {
  HistoryExtension,
  PlaceholderExtension,

  BoldMark,
  ItalicMark,
  LinkMark,

  BulletListNode,
  HardBreakNode,
  HeadingNode,
  ListItemNode,
  OrderedListNode,
} from 'tiptap-extensions'

import InlineDiffMark from './marks/inline_diff';
import InlineHTMLMark from './marks/inline_html';
import StrikeMark from './marks/strike';
import CodeMark from './marks/code';
import MathMark from './marks/math';
import EmojiNode from './nodes/emoji';
import HorizontalRuleNode from './nodes/horizontal_rule.js';
import ReferenceNode from './nodes/reference';
import BlockquoteNode from './nodes/blockquote';
import CodeBlockNode from './nodes/code_block';
import ImageNode from './nodes/image';
import VideoNode from './nodes/video';
import DetailsNode from './nodes/details';
import SummaryNode from './nodes/summary';

export default [
  new HistoryExtension,
  new PlaceholderExtension,

  new EmojiNode,
  new VideoNode,
  new DetailsNode,
  new SummaryNode,
  new ReferenceNode,
  new HorizontalRuleNode,
  // new TableOfContentsNode,
  // new TableNode,
  // new TableHeadNode,
  // new TableRowNode,
  // new TableCellNode,
  // new TaskItemNode,
  // new TaskListNode,

  new BlockquoteNode,
  new BulletListNode,
  new CodeBlockNode,
  new HeadingNode({ maxLevel: 6 }),
  new HardBreakNode,
  new ImageNode,
  new ListItemNode,
  new OrderedListNode,

  new BoldMark,
  new LinkMark,
  new ItalicMark,
  new StrikeMark,

  new InlineDiffMark,
  new InlineHTMLMark,
  new MathMark,
  new CodeMark,

  // new SuggestionsPlugin,
  // new MentionNode,
]
