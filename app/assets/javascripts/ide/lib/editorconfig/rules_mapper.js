import { isBoolean, isNumber } from 'lodash';

const map = (key, validValues) => (value) =>
  value in validValues ? { [key]: validValues[value] } : {};

const bool = (key) => (value) => (isBoolean(value) ? { [key]: value } : {});

const int = (key, isValid) => (value) =>
  isNumber(value) && isValid(value) ? { [key]: Math.trunc(value) } : {};

const rulesMapper = {
  indent_style: map('insertSpaces', { tab: false, space: true }),
  indent_size: int('tabSize', (n) => n > 0),
  tab_width: int('tabSize', (n) => n > 0),
  trim_trailing_whitespace: bool('trimTrailingWhitespace'),
  end_of_line: map('endOfLine', { crlf: 1, lf: 0 }),
  insert_final_newline: bool('insertFinalNewline'),
};

const parseValue = (x) => {
  let value = typeof x === 'string' ? x.toLowerCase() : x;
  if (/^[0-9.-]+$/.test(value)) value = Number(value);
  if (value === 'true') value = true;
  if (value === 'false') value = false;

  return value;
};

export default function mapRulesToMonaco(rules) {
  return Object.entries(rules).reduce((obj, [key, value]) => {
    return Object.assign(obj, rulesMapper[key]?.(parseValue(value)) || {});
  }, {});
}
