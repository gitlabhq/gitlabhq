import PersistentUserCallout from './persistent_user_callout';

const PERSISTENT_USER_CALLOUTS = [
  '.js-recovery-settings-callout',
  '.js-users-over-license-callout',
  '.js-admin-licensed-user-count-threshold',
  '.js-token-expiry-callout',
  '.js-registration-enabled-callout',
  '.js-openssl-callout',
  '.js-new-user-signups-cap-reached',
  '.js-security-newsletter-callout',
  '.js-approaching-seat-count-threshold',
  '.js-storage-pre-enforcement-alert',
  '.js-user-over-limit-free-plan-alert',
  '.js-minute-limit-banner',
  '.js-submit-license-usage-data-banner',
  '.js-project-usage-limitations-callout',
  '.js-namespace-storage-alert',
  '.js-web-hook-disabled-callout',
  '.js-merge-request-settings-callout',
  '.js-compliance-framework-settings-callout',
  '.js-geo-enable-hashed-storage-callout',
  '.js-geo-migrate-hashed-storage-callout',
  '.js-unlimited-members-during-trial-alert',
  '.js-branch-rules-info-callout',
  '.js-branch-rules-tip-callout',
  '.js-namespace-over-storage-users-combined-alert',
  '.js-joining-a-project-alert',
  '.js-all-seats-used',
  '.js-period-in-terraform-state-name-alert',
  '.js-new-mr-dashboard-banner',
  '.js-pipl-compliance-alert',
  '.gcp-signup-offer',
  '.js-gold-trial-callout',
];

const initCallouts = () => {
  document
    .querySelectorAll(PERSISTENT_USER_CALLOUTS)
    .forEach((calloutContainer) => PersistentUserCallout.factory(calloutContainer));
};

export default initCallouts;
