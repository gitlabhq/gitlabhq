import PersistentUserCallout from './persistent_user_callout';

const PERSISTENT_USER_CALLOUTS = [
  '.js-recovery-settings-callout',
  '.js-users-over-license-callout',
  '.js-admin-licensed-user-count-threshold',
  '.js-buy-pipeline-minutes-notification-callout',
  '.js-token-expiry-callout',
  '.js-registration-enabled-callout',
  '.js-new-user-signups-cap-reached',
  '.js-eoa-bronze-plan-banner',
  '.js-security-newsletter-callout',
  '.js-approaching-seat-count-threshold',
  '.js-storage-enforcement-banner',
  '.js-user-over-limit-free-plan-alert',
  '.js-minute-limit-banner',
  '.js-submit-license-usage-data-banner',
  '.js-project-usage-limitations-callout',
  '.js-namespace-storage-alert',
  '.js-web-hook-disabled-callout',
  '.js-merge-request-settings-callout',
  '.js-ultimate-feature-removal-banner',
  '.js-geo-enable-hashed-storage-callout',
  '.js-geo-migrate-hashed-storage-callout',
  '.js-unlimited-members-during-trial-alert',
  '.js-branch-rules-info-callout',
];

const initCallouts = () => {
  document
    .querySelectorAll(PERSISTENT_USER_CALLOUTS)
    .forEach((calloutContainer) => PersistentUserCallout.factory(calloutContainer));
};

export default initCallouts;
