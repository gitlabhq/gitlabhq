export const VERSION_CHECK_BADGE_NO_PROP_FIXTURE =
  '<div class="js-gitlab-version-check-badge"></div>';

export const VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE = `<div class="js-gitlab-version-check-badge" data-version='{ "size": "sm" }'></div>`;

export const VERSION_CHECK_BADGE_FIXTURE = `<div class="js-gitlab-version-check-badge" data-version='{ "severity": "success" }'></div>`;

export const VERSION_CHECK_BADGE_FINDER = '[data-testid="check-version-badge"]';

export const VERSION_BADGE_TEXT = 'Up to date';

export const SECURITY_MODAL_FIXTURE = `<div id="js-security-patch-upgrade-alert-modal" data-current-version="15.1" data-version='{ "details": "test details", "latest-stable-versions": "[]" }'></div>`;

export const SECURITY_MODAL_FINDER = '[data-testid="alert-modal-title"]';

export const SECURITY_MODAL_TEXT = 'Important notice - Critical patch release';
