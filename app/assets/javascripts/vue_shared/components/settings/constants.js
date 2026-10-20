export const ENFORCEMENT_MODE_ENFORCE = 'enforce';
export const ENFORCEMENT_MODE_WARN = 'warn';
export const ENFORCEMENT_MODE_AUDIT = 'audit';

// Strongest first: the row that decides how the wrapped setting renders.
export const ENFORCEMENT_MODE_PRECEDENCE = [
  ENFORCEMENT_MODE_ENFORCE,
  ENFORCEMENT_MODE_WARN,
  ENFORCEMENT_MODE_AUDIT,
];
