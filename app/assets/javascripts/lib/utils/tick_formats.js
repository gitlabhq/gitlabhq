import { createDateTimeFormat } from '../../locale';

let dateTimeFormats;

export const initDateFormats = () => {
  const dayFormat = createDateTimeFormat({ month: 'short', day: 'numeric' });
  const monthFormat = createDateTimeFormat({ month: 'long' });
  const yearFormat = createDateTimeFormat({ year: 'numeric' });

  dateTimeFormats = {
    dayFormat,
    monthFormat,
    yearFormat,
  };
};

initDateFormats();

/**
  Formats a localized date in way that it can be used for d3.js axis.tickFormat().

  That is, it displays
  - 4-digit for first of January
  - full month name for first of every month
  - day and abbreviated month otherwise

  see also https://github.com/d3/d3-3.x-api-reference/blob/master/SVG-Axes.md#tickFormat
  */
export const dateTickFormat = (date) => {
  if (date.getDate() !== 1) {
    return dateTimeFormats.dayFormat.format(date);
  }

  if (date.getMonth() > 0) {
    return dateTimeFormats.monthFormat.format(date);
  }

  return dateTimeFormats.yearFormat.format(date);
};
