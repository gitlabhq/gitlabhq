import { ENFORCEMENT_MODE_PRECEDENCE } from './constants';

export const isEnforcementRow = (row) =>
  ENFORCEMENT_MODE_PRECEDENCE.includes(row?.mode) && typeof row?.policy?.name === 'string';
