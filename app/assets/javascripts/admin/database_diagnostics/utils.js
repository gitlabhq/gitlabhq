// Severity strings come from Gitlab::Database::Diagnostics::Findings.
const SEVERITY_VARIANTS = {
  error: 'danger',
  warning: 'warning',
};

const SEVERITY_ICONS = {
  error: { name: 'error', variant: 'danger' },
  warning: { name: 'warning', variant: 'warning' },
};

// An unknown severity renders as a warning, so a severity added to the backend
// stays visible here.
export const severityVariant = (severity) => SEVERITY_VARIANTS[severity] || 'warning';

// No severity means the check found nothing, so the icon reports success. An
// unknown one falls back to a warning, as severityVariant does.
export const severityIcon = (severity) => {
  if (!severity) return { name: 'check-circle-filled', variant: 'success' };

  return SEVERITY_ICONS[severity] || SEVERITY_ICONS.warning;
};
