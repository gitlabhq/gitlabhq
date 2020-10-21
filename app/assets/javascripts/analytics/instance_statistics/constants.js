import { getDateInPast } from '~/lib/utils/datetime_utility';

export const TOTAL_DAYS_TO_SHOW = 365;
export const TODAY = new Date();
export const START_DATE = getDateInPast(TODAY, TOTAL_DAYS_TO_SHOW);
