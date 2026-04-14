import { unescape } from 'lodash-es';
import { stripHtml } from '~/lib/utils/text_utility';

export function diffLineToString(line) {
  const { rich_text: richText, text } = line;
  if (text) return text;
  return unescape(stripHtml(richText).replace(/\\n/g, '%br').replace(/\n/g, ''));
}

export function pickDirection({ line, code } = {}) {
  const { left, right } = line;
  let direction = left || right;

  if (right?.line_code === code) {
    direction = right;
  }

  return direction;
}
