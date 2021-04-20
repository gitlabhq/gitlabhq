import PersistentUserCallout from './persistent_user_callout';

const PERSISTENT_USER_CALLOUTS = [
  '.js-recovery-settings-callout',
  '.js-users-over-license-callout',
  '.js-admin-licensed-user-count-threshold',
  '.js-buy-pipeline-minutes-notification-callout',
  '.js-token-expiry-callout',
  '.js-registration-enabled-callout',
  '.js-service-templates-deprecated-callout',
  '.js-new-user-signups-cap-reached',
  '.js-eoa-bronze-plan-banner',
];

const initCallouts = () => {
  PERSISTENT_USER_CALLOUTS.forEach((calloutContainer) =>
    PersistentUserCallout.factory(document.querySelector(calloutContainer)),
  );
};

export default initCallouts;
