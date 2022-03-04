import Bold from './marks/bold';
import Code from './marks/code';
import InlineDiff from './marks/inline_diff';
import InlineHTML from './marks/inline_html';
import Italic from './marks/italic';
import Link from './marks/link';
import MathMark from './marks/math';
import Strike from './marks/strike';
import Audio from './nodes/audio';
import Blockquote from './nodes/blockquote';
import BulletList from './nodes/bullet_list';
import CodeBlock from './nodes/code_block';
import DescriptionDetails from './nodes/description_details';
import DescriptionList from './nodes/description_list';
import DescriptionTerm from './nodes/description_term';
import Details from './nodes/details';
import Doc from './nodes/doc';

import Emoji from './nodes/emoji';
import HardBreak from './nodes/hard_break';
import Heading from './nodes/heading';
import HorizontalRule from './nodes/horizontal_rule';
import Image from './nodes/image';

import ListItem from './nodes/list_item';
import OrderedList from './nodes/ordered_list';
import OrderedTaskList from './nodes/ordered_task_list';
import Paragraph from './nodes/paragraph';
import Reference from './nodes/reference';
import Summary from './nodes/summary';
import Table from './nodes/table';
import TableBody from './nodes/table_body';
import TableCell from './nodes/table_cell';
import TableHead from './nodes/table_head';
import TableHeaderRow from './nodes/table_header_row';
import TableOfContents from './nodes/table_of_contents';
import TableRow from './nodes/table_row';

import TaskList from './nodes/task_list';
import TaskListItem from './nodes/task_list_item';
import Text from './nodes/text';
import Video from './nodes/video';

// The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb transform
// GitLab Flavored Markdown (GFM) to HTML.
// The nodes and marks referenced here transform that same HTML to GFM to be copied to the clipboard.
// Every filter in lib/banzai/pipeline/gfm_pipeline.rb that generates HTML
// from GFM should have a node or mark here.
// The GFM-to-HTML-to-GFM cycle is tested in spec/features/markdown/copy_as_gfm_spec.rb.

export default {
  nodes: [
    Doc(),
    Paragraph(),
    Text(),

    Blockquote(),
    CodeBlock(),
    HardBreak(),
    Heading(),
    HorizontalRule(),
    Image(),

    Table(),
    TableHead(),
    TableBody(),
    TableHeaderRow(),
    TableRow(),
    TableCell(),

    Emoji(),
    Reference(),

    TableOfContents(),
    Video(),
    Audio(),

    BulletList(),
    OrderedList(),
    ListItem(),

    DescriptionList(),
    DescriptionTerm(),
    DescriptionDetails(),

    TaskList(),
    OrderedTaskList(),
    TaskListItem(),

    Summary(),
    Details(),
  ],

  marks: [Bold(), Italic(), Strike(), InlineDiff(), Link(), Code(), MathMark(), InlineHTML()],
};
