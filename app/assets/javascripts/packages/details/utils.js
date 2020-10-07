import { TrackingActions } from './constants';

export const trackInstallationTabChange = {
  methods: {
    trackInstallationTabChange(tabIndex) {
      const action = tabIndex === 0 ? TrackingActions.INSTALLATION : TrackingActions.REGISTRY_SETUP;
      this.track(action, { label: this.trackingLabel });
    },
  },
};
