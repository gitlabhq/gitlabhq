// Maps sort order as it appears in the URL query to API `order_by` and `sort` params.
const PRIORITY = 'priority';
const ASC = 'asc';
const DESC = 'desc';
const CREATED_AT = 'created_at';
const UPDATED_AT = 'updated_at';
const DUE_DATE = 'due_date';
const MILESTONE_DUE = 'milestone_due';
const POPULARITY = 'popularity';
const WEIGHT = 'weight';
const LABEL_PRIORITY = 'label_priority';
export const RELATIVE_POSITION = 'relative_position';
export const LOADING_LIST_ITEMS_LENGTH = 8;
export const PAGE_SIZE = 20;
export const PAGE_SIZE_MANUAL = 100;

export const sortOrderMap = {
  priority: { order_by: PRIORITY, sort: ASC }, // asc and desc are flipped for some reason
  created_date: { order_by: CREATED_AT, sort: DESC },
  created_asc: { order_by: CREATED_AT, sort: ASC },
  updated_desc: { order_by: UPDATED_AT, sort: DESC },
  updated_asc: { order_by: UPDATED_AT, sort: ASC },
  milestone_due_desc: { order_by: MILESTONE_DUE, sort: DESC },
  milestone: { order_by: MILESTONE_DUE, sort: ASC },
  due_date_desc: { order_by: DUE_DATE, sort: DESC },
  due_date: { order_by: DUE_DATE, sort: ASC },
  popularity: { order_by: POPULARITY, sort: DESC },
  popularity_asc: { order_by: POPULARITY, sort: ASC },
  label_priority: { order_by: LABEL_PRIORITY, sort: ASC }, // asc and desc are flipped
  relative_position: { order_by: RELATIVE_POSITION, sort: ASC },
  weight_desc: { order_by: WEIGHT, sort: DESC },
  weight: { order_by: WEIGHT, sort: ASC },
};
