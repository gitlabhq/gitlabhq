import { Extension } from '@tiptap/core';
import Blockquote from './blockquote';
import Bold from './bold';
import BulletList from './bullet_list';
import Code from './code';
import CodeBlockHighlight from './code_block_highlight';
import Heading from './heading';
import HardBreak from './hard_break';
import HorizontalRule from './horizontal_rule';
import Image from './image';
import Italic from './italic';
import Link from './link';
import ListItem from './list_item';
import OrderedList from './ordered_list';
import Paragraph from './paragraph';
import Strike from './strike';
import TaskList from './task_list';
import TaskItem from './task_item';
import Table from './table';
import TableCell from './table_cell';
import TableHeader from './table_header';
import TableRow from './table_row';

export default Extension.create({
  addGlobalAttributes() {
    return [
      {
        types: [
          Bold.name,
          Blockquote.name,
          BulletList.name,
          Code.name,
          CodeBlockHighlight.name,
          HardBreak.name,
          Heading.name,
          HorizontalRule.name,
          Image.name,
          Italic.name,
          Link.name,
          ListItem.name,
          OrderedList.name,
          Paragraph.name,
          Strike.name,
          TaskList.name,
          TaskItem.name,
          Table.name,
          TableCell.name,
          TableHeader.name,
          TableRow.name,
        ],
        attributes: {
          sourceMarkdown: {
            default: null,
          },
          sourceMapKey: {
            default: null,
          },
        },
      },
    ];
  },
});
