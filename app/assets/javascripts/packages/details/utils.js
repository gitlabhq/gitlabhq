import { TrackingActions } from './constants';

export const trackInstallationTabChange = {
  methods: {
    trackInstallationTabChange(tabIndex) {
      const action = tabIndex === 0 ? TrackingActions.INSTALLATION : TrackingActions.REGISTRY_SETUP;
      this.track(action, { label: this.trackingLabel });
    },
  },
};

export function generateConanRecipe(packageEntity = {}) {
  const {
    name = '',
    version = '',
    conan_metadatum: {
      package_username: packageUsername = '',
      package_channel: packageChannel = '',
    } = {},
  } = packageEntity;

  return `${name}/${version}@${packageUsername}/${packageChannel}`;
}
