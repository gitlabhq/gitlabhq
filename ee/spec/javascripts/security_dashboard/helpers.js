import vulnerabilitiesState from 'ee/security_dashboard/store/modules/vulnerabilities/state';

// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  const newState = {
    vulnerabilities: vulnerabilitiesState(),
  };
  store.replaceState(newState);
};
