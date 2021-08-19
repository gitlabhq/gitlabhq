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

export const DELETE_PACKAGE_TRACKING_ACTION = 'delete_package';
export const REQUEST_DELETE_PACKAGE_TRACKING_ACTION = 'request_delete_package';
export const CANCEL_DELETE_PACKAGE_TRACKING_ACTION = 'cancel_delete_package';
export const PULL_PACKAGE_TRACKING_ACTION = 'pull_package';
export const DELETE_PACKAGE_FILE_TRACKING_ACTION = 'delete_package_file';
export const REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'request_delete_package_file';
export const CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'cancel_delete_package_file';

export const TRACKING_LABEL_CODE_INSTRUCTION = 'code_instruction';
export const TRACKING_LABEL_CONAN_INSTALLATION = 'conan_installation';
export const TRACKING_LABEL_MAVEN_INSTALLATION = 'maven_installation';
export const TRACKING_LABEL_NPM_INSTALLATION = 'npm_installation';
export const TRACKING_LABEL_NUGET_INSTALLATION = 'nuget_installation';
export const TRACKING_LABEL_PYPI_INSTALLATION = 'pypi_installation';
export const TRACKING_LABEL_COMPOSER_INSTALLATION = 'composer_installation';

export const TRACKING_ACTION_INSTALLATION = 'installation';
export const TRACKING_ACTION_REGISTRY_SETUP = 'registry_setup';

export const TRACKING_ACTION_COPY_CONAN_COMMAND = 'copy_conan_command';
export const TRACKING_ACTION_COPY_CONAN_SETUP_COMMAND = 'copy_conan_setup_command';

export const TRACKING_ACTION_COPY_MAVEN_XML = 'copy_maven_xml';
export const TRACKING_ACTION_COPY_MAVEN_COMMAND = 'copy_maven_command';
export const TRACKING_ACTION_COPY_MAVEN_SETUP = 'copy_maven_setup_xml';
export const TRACKING_ACTION_COPY_GRADLE_INSTALL_COMMAND = 'copy_gradle_install_command';
export const TRACKING_ACTION_COPY_GRADLE_ADD_TO_SOURCE_COMMAND =
  'copy_gradle_add_to_source_command';
export const TRACKING_ACTION_COPY_KOTLIN_INSTALL_COMMAND = 'copy_kotlin_install_command';
export const TRACKING_ACTION_COPY_KOTLIN_ADD_TO_SOURCE_COMMAND =
  'copy_kotlin_add_to_source_command';

export const TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND = 'copy_npm_install_command';
export const TRACKING_ACTION_COPY_NPM_SETUP_COMMAND = 'copy_npm_setup_command';
export const TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND = 'copy_yarn_install_command';
export const TRACKING_ACTION_COPY_YARN_SETUP_COMMAND = 'copy_yarn_setup_command';

export const TRACKING_ACTION_COPY_NUGET_INSTALL_COMMAND = 'copy_nuget_install_command';
export const TRACKING_ACTION_COPY_NUGET_SETUP_COMMAND = 'copy_nuget_setup_command';

export const TRACKING_ACTION_COPY_PIP_INSTALL_COMMAND = 'copy_pip_install_command';
export const TRACKING_ACTION_COPY_PYPI_SETUP_COMMAND = 'copy_pypi_setup_command';

export const TRACKING_ACTION_COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND =
  'copy_composer_registry_include_command';
export const TRACKING_ACTION_COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND =
  'copy_composer_package_include_command';

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

export const PACKAGE_ERROR_STATUS = 'ERROR';
export const PACKAGE_DEFAULT_STATUS = 'DEFAULT';
export const PACKAGE_HIDDEN_STATUS = 'HIDDEN';
export const PACKAGE_PROCESSING_STATUS = 'PROCESSING';

export const NPM_PACKAGE_MANAGER = 'npm';
export const YARN_PACKAGE_MANAGER = 'yarn';
