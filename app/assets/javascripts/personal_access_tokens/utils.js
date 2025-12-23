import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

const emptyDateField = __('Never');

export const timeFormattedAsDate = (time) =>
  time ? localeDateFormat.asDate.format(newDate(time)) : emptyDateField;

export const timeFormattedAsDateFull = (time) =>
  time ? localeDateFormat.asDateTimeFull.format(newDate(time)) : emptyDateField;
