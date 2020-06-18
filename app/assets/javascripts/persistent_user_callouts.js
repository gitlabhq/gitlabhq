import PersistentUserCallout from './persistent_user_callout';

const PERSISTENT_USER_CALLOUTS = [
  '.js-recovery-settings-callout',
  '.js-users-over-license-callout',
  '.js-admin-licensed-user-count-threshold',
];

const initCallouts = () => {
  PERSISTENT_USER_CALLOUTS.forEach(calloutContainer =>
    PersistentUserCallout.factory(document.querySelector(calloutContainer)),
  );
};

export default initCallouts;
