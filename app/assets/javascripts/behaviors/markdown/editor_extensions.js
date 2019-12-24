import Doc from './nodes/doc';
import Paragraph from './nodes/paragraph';
import Text from './nodes/text';

import Blockquote from './nodes/blockquote';
import CodeBlock from './nodes/code_block';
import HardBreak from './nodes/hard_break';
import Heading from './nodes/heading';
import HorizontalRule from './nodes/horizontal_rule';
import Image from './nodes/image';

import Table from './nodes/table';
import TableHead from './nodes/table_head';
import TableBody from './nodes/table_body';
import TableHeaderRow from './nodes/table_header_row';
import TableRow from './nodes/table_row';
import TableCell from './nodes/table_cell';

import Emoji from './nodes/emoji';
import Reference from './nodes/reference';

import TableOfContents from './nodes/table_of_contents';
import Video from './nodes/video';
import Audio from './nodes/audio';

import BulletList from './nodes/bullet_list';
import OrderedList from './nodes/ordered_list';
import ListItem from './nodes/list_item';

import DescriptionList from './nodes/description_list';
import DescriptionTerm from './nodes/description_term';
import DescriptionDetails from './nodes/description_details';

import TaskList from './nodes/task_list';
import OrderedTaskList from './nodes/ordered_task_list';
import TaskListItem from './nodes/task_list_item';

import Summary from './nodes/summary';
import Details from './nodes/details';

import Bold from './marks/bold';
import Italic from './marks/italic';
import Strike from './marks/strike';
import InlineDiff from './marks/inline_diff';

import Link from './marks/link';
import Code from './marks/code';
import MathMark from './marks/math';
import InlineHTML from './marks/inline_html';

// The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb transform
// GitLab Flavored Markdown (GFM) to HTML.
// The nodes and marks referenced here transform that same HTML to GFM to be copied to the clipboard.
// Every filter in lib/banzai/pipeline/gfm_pipeline.rb that generates HTML
// from GFM should have a node or mark here.
// The GFM-to-HTML-to-GFM cycle is tested in spec/features/markdown/copy_as_gfm_spec.rb.

export default [
  new Doc(),
  new Paragraph(),
  new Text(),

  new Blockquote(),
  new CodeBlock(),
  new HardBreak(),
  new Heading({ maxLevel: 6 }),
  new HorizontalRule(),
  new Image(),

  new Table(),
  new TableHead(),
  new TableBody(),
  new TableHeaderRow(),
  new TableRow(),
  new TableCell(),

  new Emoji(),
  new Reference(),

  new TableOfContents(),
  new Video(),
  new Audio(),

  new BulletList(),
  new OrderedList(),
  new ListItem(),

  new DescriptionList(),
  new DescriptionTerm(),
  new DescriptionDetails(),

  new TaskList(),
  new OrderedTaskList(),
  new TaskListItem(),

  new Summary(),
  new Details(),

  new Bold(),
  new Italic(),
  new Strike(),
  new InlineDiff(),

  new Link(),
  new Code(),
  new MathMark(),
  new InlineHTML(),
];
