/**
 * Vulnerability severities as provided by the backend on vulnerability
 * objects.
 */
export const CRITICAL = 'critical';
export const HIGH = 'high';
export const MEDIUM = 'medium';
export const LOW = 'low';
export const INFO = 'info';
export const UNKNOWN = 'unknown';

/**
 * All vulnerability severities in decreasing order.
 */
export const SEVERITIES = [CRITICAL, HIGH, MEDIUM, LOW, INFO, UNKNOWN];

export const SEVERITY_COUNT_LIMIT = 1000;
