import { __ } from '~/locale';
import {
  CREATED_ASC,
  CREATED_DESC,
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
  [TITLE_ASC]: 'title_asc',
  [TITLE_DESC]: 'title_desc',
  [UPDATED_ASC]: 'updated_asc',
  [UPDATED_DESC]: 'updated_desc',
};
