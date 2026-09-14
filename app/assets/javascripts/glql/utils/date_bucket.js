import {
  DATE_ONLY_REGEX,
  newDate,
  nDaysAfter,
} from '~/lib/utils/datetime/date_calculation_utility';
import { toISODateFormat } from '~/lib/utils/datetime/date_format_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

// The round trip rejects shape-only matches like "2026-02-30" that Date would
// silently roll over to another day.
const isRealCalendarDate = (value) =>
  DATE_ONLY_REGEX.test(value) && toISODateFormat(newDate(value)) === value;

// Bucket starts arrive date-only for weekly/monthly but as ISO datetimes
// for daily (ClickHouse's toStartOfInterval returns DateTime for day), so
// extract and validate the date part; anything else is not a bucket value.
const BUCKET_TIME_SUFFIX_REGEX = /^T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/;

export const bucketDateOf = (value) => {
  if (typeof value !== 'string') return null;
  const datePart = value.slice(0, 10);
  if (!isRealCalendarDate(datePart)) return null;
  const timePart = value.slice(10);
  if (timePart && !BUCKET_TIME_SUFFIX_REGEX.test(timePart)) return null;
  return datePart;
};

// newDate parses "YYYY-MM-DD" as a local date, keeping the label on the
// bucket's own day in every viewer timezone. Daily and weekly labels drop
// the year unless `includeYear` is set - chart axes carry the year context.
const formatDateLabel = (value, granularity, includeYear) => {
  const date = newDate(value);
  const dayFormat = includeYear ? localeDateFormat.asDate : localeDateFormat.asDateWithoutYear;
  if (granularity === 'weekly') {
    return dayFormat.formatRange(date, nDaysAfter(date, 6));
  }
  if (granularity === 'monthly') return localeDateFormat.asMonthYear.format(date);
  if (granularity === 'yearly') return String(date.getFullYear());
  return dayFormat.format(date);
};

export const formatBucketDate = (value, granularity, includeYear = false) => {
  const bucketDate = bucketDateOf(value);
  return bucketDate ? formatDateLabel(bucketDate, granularity, includeYear) : String(value);
};
