import { __, s__ } from '~/locale';

export const PACKAGE_TYPE_CONAN = 'CONAN';
export const PACKAGE_TYPE_MAVEN = 'MAVEN';
export const PACKAGE_TYPE_NPM = 'NPM';
export const PACKAGE_TYPE_NUGET = 'NUGET';
export const PACKAGE_TYPE_PYPI = 'PYPI';
export const PACKAGE_TYPE_COMPOSER = 'COMPOSER';
export const PACKAGE_TYPE_RUBYGEMS = 'RUBYGEMS';
export const PACKAGE_TYPE_GENERIC = 'GENERIC';
export const PACKAGE_TYPE_DEBIAN = 'DEBIAN';
export const PACKAGE_TYPE_HELM = 'HELM';
export const PACKAGE_TYPE_TERRAFORM = 'terraform_module';

export const DELETE_PACKAGE_TRACKING_ACTION = 'delete_package';
export const REQUEST_DELETE_PACKAGE_TRACKING_ACTION = 'request_delete_package';
export const CANCEL_DELETE_PACKAGE_TRACKING_ACTION = 'cancel_delete_package';
export const PULL_PACKAGE_TRACKING_ACTION = 'pull_package';
export const DELETE_PACKAGE_FILE_TRACKING_ACTION = 'delete_package_file';
export const REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'request_delete_package_file';
export const CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'cancel_delete_package_file';

export const TrackingCategories = {
  [PACKAGE_TYPE_MAVEN]: 'MavenPackages',
  [PACKAGE_TYPE_NPM]: 'NpmPackages',
  [PACKAGE_TYPE_CONAN]: 'ConanPackages',
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
export const FETCH_PACKAGE_DETAILS_ERROR_MESSAGE = s__(
  'PackageRegistry|Failed to load the package data',
);

export const PACKAGE_ERROR_STATUS = 'error';
export const PACKAGE_DEFAULT_STATUS = 'default';
export const PACKAGE_HIDDEN_STATUS = 'hidden';
export const PACKAGE_PROCESSING_STATUS = 'processing';
