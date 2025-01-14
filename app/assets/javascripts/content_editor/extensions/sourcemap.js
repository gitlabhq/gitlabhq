import { Extension } from '@tiptap/core';
import { getSourceMapAttributes } from '../services/markdown_sourcemap';
import Audio from './audio';
import Blockquote from './blockquote';
import Bold from './bold';
import BulletList from './bullet_list';
import Code from './code';
import CodeBlockHighlight from './code_block_highlight';
import Diagram from './diagram';
import FootnoteReference from './footnote_reference';
import FootnoteDefinition from './footnote_definition';
import Frontmatter from './frontmatter';
import Heading from './heading';
import HardBreak from './hard_break';
import HorizontalRule from './horizontal_rule';
import HTMLNodes from './html_nodes';
import Image from './image';
import Italic from './italic';
import InlineDiff from './inline_diff';
import Link from './link';
import ListItem from './list_item';
import MathInline from './math_inline';
import OrderedList from './ordered_list';
import Paragraph from './paragraph';
import ReferenceDefinition from './reference_definition';
import Strike from './strike';
import TaskList from './task_list';
import TaskItem from './task_item';
import Table from './table';
import TableCell from './table_cell';
import TableHeader from './table_header';
import TableRow from './table_row';
import TableOfContents from './table_of_contents';
import Video from './video';

export default Extension.create({
  name: 'sourcemap',

  addGlobalAttributes() {
    return [
      {
        types: [
          Audio.name,
          Bold.name,
          Blockquote.name,
          BulletList.name,
          Code.name,
          CodeBlockHighlight.name,
          Diagram.name,
          FootnoteReference.name,
          FootnoteDefinition.name,
          Frontmatter.name,
          HardBreak.name,
          Heading.name,
          HorizontalRule.name,
          Image.name,
          Italic.name,
          InlineDiff.name,
          Link.name,
          ListItem.name,
          MathInline.name,
          OrderedList.name,
          Paragraph.name,
          ReferenceDefinition.name,
          Strike.name,
          TaskList.name,
          TaskItem.name,
          Table.name,
          TableCell.name,
          TableHeader.name,
          TableRow.name,
          TableOfContents.name,
          Video.name,
          ...HTMLNodes.map((htmlNode) => htmlNode.name),
        ],
        attributes: getSourceMapAttributes(),
      },
    ];
  },
});
