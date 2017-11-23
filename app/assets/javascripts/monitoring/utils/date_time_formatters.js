import {
  timeFormat as d3TimeFormat,
  bisector } from '../../common_d3/index';

export const dateFormat = d3TimeFormat('%b %-d, %Y');
export const timeFormat = d3TimeFormat('%-I:%M%p');
export const dateFormatWithName = d3TimeFormat('%a, %b %-d');
export const bisectDate = bisector(d => d.time).left;
