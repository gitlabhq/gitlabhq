import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

export const PACKAGE_SETTINGS_HEADER = s__('PackageRegistry|Duplicate packages');
export const PACKAGE_SETTINGS_DESCRIPTION = s__(
  'PackageRegistry|Allow packages with the same name and version to be uploaded to the registry. The newest version of a package is always used when installing.',
);
export const PACKAGE_FORMATS_TABLE_HEADER = s__('PackageRegistry|Package formats');
export const MAVEN_PACKAGE_FORMAT = s__('PackageRegistry|Maven');
export const NPM_PACKAGE_FORMAT = s__('PackageRegistry|npm');
export const PYPI_PACKAGE_FORMAT = s__('PackageRegistry|PyPI');
export const GENERIC_PACKAGE_FORMAT = s__('PackageRegistry|Generic');
export const NUGET_PACKAGE_FORMAT = s__('PackageRegistry|NuGet');
export const TERRAFORM_MODULE_PACKAGE_FORMAT = s__('PackageRegistry|Terraform module');

export const DUPLICATES_TOGGLE_LABEL = s__('PackageRegistry|Allow duplicates');
export const DUPLICATES_SETTING_EXCEPTION_TITLE = __('Exceptions');
export const DUPLICATES_SETTINGS_EXCEPTION_LEGEND = s__(
  'PackageRegistry|Publish packages if their name or version matches this regex.',
);

export const PACKAGE_FORWARDING_SECURITY_DESCRIPTION = s__(
  'PackageRegistry|There are security risks if packages are deleted while request forwarding is enabled. %{docLinkStart}What are the risks?%{docLinkEnd}',
);
export const PACKAGE_FORWARDING_SETTINGS_HEADER = s__('PackageRegistry|Package forwarding');
export const PACKAGE_FORWARDING_SETTINGS_DESCRIPTION = s__(
  'PackageRegistry|Forward package requests to a public registry if the packages are not found in the GitLab package registry.',
);
export const PACKAGE_FORWARDING_CHECKBOX_LABEL = s__(
  `PackageRegistry|Forward %{packageType} package requests`,
);
export const PACKAGE_FORWARDING_ENFORCE_LABEL = s__(
  `PackageRegistry|Enforce %{packageType} setting for all subgroups`,
);

const MAVEN_PACKAGE_REQUESTS_FORWARDING = 'mavenPackageRequestsForwarding';
const LOCK_MAVEN_PACKAGE_REQUESTS_FORWARDING = 'lockMavenPackageRequestsForwarding';
const MAVEN_PACKAGE_REQUESTS_FORWARDING_LOCKED = 'mavenPackageRequestsForwardingLocked';
const NPM_PACKAGE_REQUESTS_FORWARDING = 'npmPackageRequestsForwarding';
const LOCK_NPM_PACKAGE_REQUESTS_FORWARDING = 'lockNpmPackageRequestsForwarding';
const NPM_PACKAGE_REQUESTS_FORWARDING_LOCKED = 'npmPackageRequestsForwardingLocked';
const PYPI_PACKAGE_REQUESTS_FORWARDING = 'pypiPackageRequestsForwarding';
const LOCK_PYPI_PACKAGE_REQUESTS_FORWARDING = 'lockPypiPackageRequestsForwarding';
const PYPI_PACKAGE_REQUESTS_FORWARDING_LOCKED = 'pypiPackageRequestsForwardingLocked';

export const PACKAGE_FORWARDING_FORM_BUTTON = __('Save changes');

export const DEPENDENCY_PROXY_HEADER = s__('DependencyProxy|Dependency Proxy');
export const DEPENDENCY_PROXY_DESCRIPTION = s__(
  'DependencyProxy|Enable the Dependency Proxy to cache container images from Docker Hub and automatically clear the cache.',
);

export const PACKAGE_FORWARDING_FIELDS = [
  {
    label: NPM_PACKAGE_FORMAT,
    testid: 'npm',
    modelNames: {
      forwarding: NPM_PACKAGE_REQUESTS_FORWARDING,
      lockForwarding: LOCK_NPM_PACKAGE_REQUESTS_FORWARDING,
      isLocked: NPM_PACKAGE_REQUESTS_FORWARDING_LOCKED,
    },
  },
  {
    label: PYPI_PACKAGE_FORMAT,
    testid: 'pypi',
    modelNames: {
      forwarding: PYPI_PACKAGE_REQUESTS_FORWARDING,
      lockForwarding: LOCK_PYPI_PACKAGE_REQUESTS_FORWARDING,
      isLocked: PYPI_PACKAGE_REQUESTS_FORWARDING_LOCKED,
    },
  },
];

export const MAVEN_FORWARDING_FIELDS = {
  label: MAVEN_PACKAGE_FORMAT,
  testid: 'maven',
  modelNames: {
    forwarding: MAVEN_PACKAGE_REQUESTS_FORWARDING,
    lockForwarding: LOCK_MAVEN_PACKAGE_REQUESTS_FORWARDING,
    isLocked: MAVEN_PACKAGE_REQUESTS_FORWARDING_LOCKED,
  },
};

// Parameters

export const DEPENDENCY_PROXY_DOCS_PATH = helpPagePath('user/packages/dependency_proxy/_index');
export const REQUEST_FORWARDING_HELP_PAGE_PATH = helpPagePath(
  'user/packages/package_registry/supported_functionality',
  { anchor: 'deleting-packages' },
);
