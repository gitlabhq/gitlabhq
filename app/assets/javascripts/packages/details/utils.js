import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { TrackingActions, InformationType } from './constants';
import { PackageType } from '../shared/constants';
import { orderBy } from 'lodash';

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

export function generatePackageInfo(packageEntity = {}) {
  const information = [];

  if (packageEntity.package_type === PackageType.CONAN) {
    information.push({
      order: 1,
      label: __('Recipe'),
      value: generateConanRecipe(packageEntity),
    });
  } else {
    information.push({
      order: 1,
      label: __('Name'),
      value: packageEntity.name || '',
    });
  }

  if (packageEntity.package_type === PackageType.NUGET) {
    const {
      nuget_metadatum: { project_url: projectUrl, license_url: licenseUrl } = {},
    } = packageEntity;

    if (projectUrl) {
      information.push({
        order: 3,
        label: __('Project URL'),
        value: projectUrl,
        type: InformationType.LINK,
      });
    }

    if (licenseUrl) {
      information.push({
        order: 4,
        label: __('License URL'),
        value: licenseUrl,
        type: InformationType.LINK,
      });
    }
  }

  return orderBy(
    [
      ...information,
      {
        order: 2,
        label: __('Version'),
        value: packageEntity.version || '',
      },
      {
        order: 5,
        label: __('Created on'),
        value: formatDate(packageEntity.created_at),
      },
      {
        order: 6,
        label: __('Updated at'),
        value: formatDate(packageEntity.updated_at),
      },
    ],
    ['order'],
  );
}
