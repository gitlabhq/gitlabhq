import { timeFormat as time } from 'd3-time-format';
import { timeSecond, timeMinute, timeHour, timeDay, timeMonth, timeYear } from 'd3-time';
import { bisector } from 'd3-array';

const d3 = { time, bisector, timeSecond, timeMinute, timeHour, timeDay, timeMonth, timeYear };

export const dateFormat = d3.time('%b %-d, %Y');
export const timeFormat = d3.time('%-I:%M%p');
export const dateFormatWithName = d3.time('%a, %b %-d');
export const bisectDate = d3.bisector(d => d.time).left;

const formatMillisecond = d3.time('.%L');
const formatSecond = d3.time(':%S');
const formatMinute = d3.time('%-I:%M');
const formatHour = d3.time('%-I %p');
const formatDay = d3.time('%a %d');
const formatWeek = d3.time('%b %d');
const formatMonth = d3.time('%B');
const formatYear = d3.time('%Y');

export function timeScaleFormat(date) {
  let formatFunction;
  if (d3.timeSecond(date) < date) {
    formatFunction = formatMillisecond;
  } else if (d3.timeMinute(date) < date) {
    formatFunction = formatSecond;
  } else if (d3.timeHour(date) < date) {
    formatFunction = formatMinute;
  } else if (d3.timeDay(date) < date) {
    formatFunction = formatHour;
  } else if (d3.timeWeek(date) < date) {
    formatFunction = formatDay;
  } else if (d3.timeMonth(date) < date) {
    formatFunction = formatWeek;
  } else if (d3.timeYear(date) < date) {
    formatFunction = formatMonth;
  } else {
    formatFunction = formatYear;
  }
  return formatFunction(date);
}
