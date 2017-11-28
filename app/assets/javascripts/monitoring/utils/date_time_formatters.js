import { timeFormat as time } from 'd3-time-format';
import { bisector } from 'd3-array';

export const dateFormat = time('%b %-d, %Y');
export const timeFormat = time('%-I:%M%p');
export const dateFormatWithName = time('%a, %b %-d');
export const bisectDate = bisector(d => d.time).left;
