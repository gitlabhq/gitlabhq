import {
  timeFormat as d3TimeFormat,
  bisector } from 'd3';

export const dateFormat = d3TimeFormat('%b %-d, %Y');
export const timeFormat = d3TimeFormat('%-I:%M%p');
export const dateFormatWithName = d3TimeFormat('%a, %b %-d');
export const bisectDate = bisector(d => d.time).left;
