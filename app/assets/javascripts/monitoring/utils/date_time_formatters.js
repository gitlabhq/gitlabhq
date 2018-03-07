import { timeFormat as time } from 'd3-time-format';
import { timeSecond, timeMinute, timeHour, timeDay, timeWeek, timeMonth, timeYear } from 'd3-time';
import { bisector } from 'd3-array';

const d3 = {
  time,
  bisector,
  timeSecond,
  timeMinute,
  timeHour,
  timeDay,
  timeWeek,
  timeMonth,
  timeYear,
};

export const dateFormat = d3.time('%a, %b %-d');
export const timeFormat = d3.time('%-I:%M%p');
export const dateFormatWithName = d3.time('%a, %b %-d');
export const bisectDate = d3.bisector(d => d.time).left;

export function timeScaleFormat(date) {
  let formatFunction;
  if (d3.timeSecond(date) < date) {
    formatFunction = d3.time('.%L');
  } else if (d3.timeMinute(date) < date) {
    formatFunction = d3.time(':%S');
  } else if (d3.timeHour(date) < date) {
    formatFunction = d3.time('%-I:%M');
  } else if (d3.timeDay(date) < date) {
    formatFunction = d3.time('%-I %p');
  } else if (d3.timeWeek(date) < date) {
    formatFunction = d3.time('%a %d');
  } else if (d3.timeMonth(date) < date) {
    formatFunction = d3.time('%b %d');
  } else if (d3.timeYear(date) < date) {
    formatFunction = d3.time('%B');
  } else {
    formatFunction = d3.time('%Y');
  }
  return formatFunction(date);
}
