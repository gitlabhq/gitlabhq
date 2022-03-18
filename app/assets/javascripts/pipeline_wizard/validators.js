import { isSeq } from 'yaml';

export const isValidStepSeq = (v) =>
  isSeq(v) && v.items.every((s) => s.get('inputs') && s.get('template'));
