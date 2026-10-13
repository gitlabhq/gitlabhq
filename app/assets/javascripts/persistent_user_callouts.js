import PersistentUserCallout from './persistent_user_callout';

const PERSISTENT_USER_CALLOUTS = [
  '.js-persistent-callout',
  // NOTE: unique callouts selectors are to be removed within https://gitlab.com/gitlab-org/gitlab/-/issues/527723
  '.js-admin-licensed-user-count-threshold',
  '.js-openssl-callout',
  '.js-new-user-signups-cap-reached',
  '.js-approaching-seat-count-threshold',
  '.js-reached-seat-count-threshold',
  '.js-overage-seat-count-threshold',
  '.js-user-over-limit-free-plan-alert',
  '.js-minute-limit-banner',
  '.js-submit-license-usage-data-banner',
  '.js-namespace-storage-alert',
  '.js-web-hook-disabled-callout',
  '.js-branch-rules-tip-callout',
  '.js-namespace-over-storage-users-combined-alert',
  '.js-joining-a-project-alert',
  '.js-period-in-terraform-state-name-alert',
  '.js-pipl-compliance-alert',
];

const initCallouts = () => {
  document
    .querySelectorAll(PERSISTENT_USER_CALLOUTS)
    .forEach((calloutContainer) => PersistentUserCallout.factory(calloutContainer));
};

export default initCallouts;
