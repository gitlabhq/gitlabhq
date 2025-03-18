import { __ } from '~/locale';
import {
  CREATED_ASC,
  CREATED_DESC,
  DUE_DATE_ASC,
  DUE_DATE_DESC,
  START_DATE_ASC,
  START_DATE_DESC,
  TITLE_ASC,
  TITLE_DESC,
  UPDATED_ASC,
  UPDATED_DESC,
} from '~/issues/list/constants';

export const sortOptions = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      ascending: CREATED_ASC,
      descending: CREATED_DESC,
    },
  },
  {
    id: 2,
    title: __('Updated date'),
    sortDirection: {
      ascending: UPDATED_ASC,
      descending: UPDATED_DESC,
    },
  },
  {
    id: 3,
    title: __('Start date'),
    sortDirection: {
      ascending: START_DATE_ASC,
      descending: START_DATE_DESC,
    },
  },
  {
    id: 4,
    title: __('Due date'),
    sortDirection: {
      ascending: DUE_DATE_ASC,
      descending: DUE_DATE_DESC,
    },
  },
  {
    id: 5,
    title: __('Title'),
    sortDirection: {
      ascending: TITLE_ASC,
      descending: TITLE_DESC,
    },
  },
];

export const urlSortParams = {
  [CREATED_ASC]: 'created_asc',
  [CREATED_DESC]: 'created_date',
  [DUE_DATE_ASC]: 'due_date_asc',
  [DUE_DATE_DESC]: 'due_date_desc',
  [START_DATE_ASC]: 'start_date_asc',
  [START_DATE_DESC]: 'start_date_desc',
  [TITLE_ASC]: 'title_asc',
  [TITLE_DESC]: 'title_desc',
  [UPDATED_ASC]: 'updated_asc',
  [UPDATED_DESC]: 'updated_desc',
};
