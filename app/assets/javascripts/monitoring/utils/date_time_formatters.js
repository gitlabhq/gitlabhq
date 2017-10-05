import d3 from 'd3';

export const dateFormat = d3.time.format('%b %-d, %Y');
export const timeFormat = d3.time.format('%-I:%M%p');
export const bisectDate = d3.bisector(d => d.time).left;

export const timeScaleFormat = d3.time.format.multi([
  ['.%L', d => d.getMilliseconds()],
  [':%S', d => d.getSeconds()],
  ['%-I:%M', d => d.getMinutes()],
  ['%-I %p', d => d.getHours()],
  ['%a %-d', d => d.getDay() && d.getDate() !== 1],
  ['%b %-d', d => d.getDate() !== 1],
  ['%B', d => d.getMonth()],
  ['%Y', () => true],
]);
