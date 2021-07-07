import { masks } from 'dateformat';

export const DATE_RANGE_LIMIT = 180;
export const OFFSET_DATE_BY_ONE = 1;
export const PROJECTS_PER_PAGE = 50;

const { isoDate, mediumDate } = masks;
export const dateFormats = {
  isoDate,
  defaultDate: mediumDate,
  defaultDateTime: 'mmm d, yyyy h:MMtt',
};
