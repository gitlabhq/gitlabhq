import { s__ } from '~/locale';
import { VIEW_MODE_LIST, VIEW_MODE_TABLE } from '~/work_items/constants';

// A board's columns can only group by status, which is EE-only, so CE offers no board view mode.
export const hasBoardViewMode = false;

export const viewModeOptions = [
  {
    value: VIEW_MODE_LIST,
    text: s__('WorkItemPlanningView|List'),
    props: { icon: 'list-bulleted' },
  },
  {
    value: VIEW_MODE_TABLE,
    text: s__('WorkItemPlanningView|Table'),
    props: { icon: 'table' },
  },
];
