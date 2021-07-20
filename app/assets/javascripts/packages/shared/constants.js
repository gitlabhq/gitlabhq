import { __, s__ } from '~/locale';

export const PackageType = {
  CONAN: 'conan',
  MAVEN: 'maven',
  NPM: 'npm',
  NUGET: 'nuget',
  PYPI: 'pypi',
  COMPOSER: 'composer',
  RUBYGEMS: 'rubygems',
  GENERIC: 'generic',
  DEBIAN: 'debian',
  HELM: 'helm',
};

// we want this separated from the main dictionary to avoid it being pulled in the search of package
export const TERRAFORM_PACKAGE_TYPE = 'terraform_module';

export const TrackingActions = {
  DELETE_PACKAGE: 'delete_package',
  REQUEST_DELETE_PACKAGE: 'request_delete_package',
  CANCEL_DELETE_PACKAGE: 'cancel_delete_package',
  PULL_PACKAGE: 'pull_package',
  DELETE_PACKAGE_FILE: 'delete_package_file',
  REQUEST_DELETE_PACKAGE_FILE: 'request_delete_package_file',
  CANCEL_DELETE_PACKAGE_FILE: 'cancel_delete_package_file',
};

export const TrackingCategories = {
  [PackageType.MAVEN]: 'MavenPackages',
  [PackageType.NPM]: 'NpmPackages',
  [PackageType.CONAN]: 'ConanPackages',
};

export const SHOW_DELETE_SUCCESS_ALERT = 'showSuccessDeleteAlert';
export const DELETE_PACKAGE_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package.',
);
export const DELETE_PACKAGE_FILE_ERROR_MESSAGE = s__(
  __('PackageRegistry|Something went wrong while deleting the package file.'),
);
export const DELETE_PACKAGE_FILE_SUCCESS_MESSAGE = s__(
  'PackageRegistry|Package file deleted successfully',
);

export const PACKAGE_ERROR_STATUS = 'error';
export const PACKAGE_DEFAULT_STATUS = 'default';
export const PACKAGE_HIDDEN_STATUS = 'hidden';
export const PACKAGE_PROCESSING_STATUS = 'processing';
