import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export {
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  PULL_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGE_FILE_TRACKING_ACTION,
  DELETE_PACKAGE_FILES_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  REQUEST_DELETE_SELECTED_PACKAGE_FILE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  SELECT_PACKAGE_FILE_TRACKING_ACTION,
} from '~/packages_and_registries/shared/constants';

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
export const PACKAGE_TYPE_ML_MODEL = 'ML_MODEL';

export const TRACKING_LABEL_CODE_INSTRUCTION = 'code_instruction';
export const TRACKING_LABEL_MAVEN_INSTALLATION = 'maven_installation';
export const MAVEN_INSTALLATION_COMMAND = 'mvn install';

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

export const TRACKING_LABEL_PACKAGE_ASSET = 'package_assets';

export const TRACKING_ACTION_EXPAND_PACKAGE_ASSET = 'expand_package_asset';
export const TRACKING_ACTION_COPY_PACKAGE_ASSET_SHA = 'copy_package_asset_sha';

export const TRACKING_ACTION_CLICK_PIPELINE_LINK = 'click_pipeline_link_from_package';
export const TRACKING_ACTION_CLICK_COMMIT_LINK = 'click_commit_link_from_package';

export const TRACKING_LABEL_PACKAGE_HISTORY = 'package_history';

export const SHOW_DELETE_SUCCESS_ALERT = 'showSuccessDeleteAlert';

export const DELETE_MODAL_TITLE = s__('PackageRegistry|Delete package version');
export const DELETE_MODAL_CONTENT = s__(
  `PackageRegistry|You are about to delete version %{version} of %{name}. Are you sure?`,
);
export const DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT = s__(
  `PackageRegistry|Deleting all package assets will remove version %{version} of %{name}. Are you sure?`,
);
export const DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT = s__(
  `PackageRegistry|Deleting the last package asset will remove version %{version} of %{name}. Are you sure?`,
);
export const DELETE_PACKAGE_FILE_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package asset.',
);
export const DELETE_PACKAGE_FILE_SUCCESS_MESSAGE = s__(
  'PackageRegistry|Package asset deleted successfully',
);
export const DELETE_PACKAGE_FILES_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package assets.',
);
export const DELETE_PACKAGE_FILES_SUCCESS_MESSAGE = s__(
  'PackageRegistry|Package assets deleted successfully',
);
export const FETCH_PACKAGE_DETAILS_ERROR_MESSAGE = s__(
  'PackageRegistry|Failed to load the package data',
);
export const FETCH_PACKAGE_PIPELINES_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while fetching the package history.',
);
export const FETCH_PACKAGE_METADATA_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while fetching the package metadata.',
);
export const FETCH_PACKAGE_FILES_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while fetching package assets.',
);

export const DELETE_PACKAGES_TRACKING_ACTION = 'delete_packages';
export const REQUEST_DELETE_PACKAGES_TRACKING_ACTION = 'request_delete_packages';
export const CANCEL_DELETE_PACKAGES_TRACKING_ACTION = 'cancel_delete_packages';

export const DELETE_PACKAGE_VERSIONS_TRACKING_ACTION = 'delete_package_versions';
export const REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION = 'request_delete_package_versions';
export const CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION = 'cancel_delete_package_versions';

export const DELETE_PACKAGE_VERSION_TRACKING_ACTION = 'delete_package_version';
export const REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION = 'request_delete_package_version';
export const CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION = 'cancel_delete_package_version';

export const FETCH_PACKAGE_VERSIONS_ERROR_MESSAGE = s__(
  'PackageRegistry|Failed to load version data',
);

export const DELETE_PACKAGES_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting packages.',
);
export const DELETE_PACKAGES_SUCCESS_MESSAGE = s__('PackageRegistry|Packages deleted successfully');

export const DELETE_PACKAGES_MODAL_TITLE = s__('PackageRegistry|Delete packages');
export const DELETE_PACKAGE_MODAL_PRIMARY_ACTION = s__('PackageRegistry|Permanently delete');
export const DELETE_PACKAGES_MODAL_DESCRIPTION = s__(
  'PackageRegistry|You are about to delete %{count} packages. This operation is irreversible.',
);
export const DELETE_PACKAGE_WITH_REQUEST_FORWARDING_PRIMARY_ACTION = s__(
  'PackageRegistry|Yes, delete package',
);
export const DELETE_PACKAGES_WITH_REQUEST_FORWARDING_PRIMARY_ACTION = s__(
  'PackageRegistry|Yes, delete selected packages',
);
export const DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT = s__(
  'PackageRegistry|Deleting this package while request forwarding is enabled for the project can pose a security risk. Do you want to delete %{name} version %{version} anyway? %{docLinkStart}What are the risks?%{docLinkEnd}',
);
export const DELETE_PACKAGES_REQUEST_FORWARDING_MODAL_CONTENT = s__(
  'PackageRegistry|Some of the selected package formats allow request forwarding. Deleting a package while request forwarding is enabled for the project can pose a security risk. Do you want to proceed with deleting the selected packages? %{docLinkStart}What are the risks?%{docLinkEnd}',
);

export const DELETE_PACKAGE_TEXT = s__('PackageRegistry|Delete package');
export const DELETE_PACKAGE_SUCCESS_MESSAGE = s__('PackageRegistry|Package deleted successfully');
export const DELETE_PACKAGE_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package.',
);

export const ERRORED_PACKAGE_TEXT = s__(
  'PackageRegistry|Invalid Package: failed metadata extraction',
);
export const ERROR_PUBLISHING = s__('PackageRegistry|Error publishing');
export const WARNING_TEXT = __('Warning');

export const PACKAGE_REGISTRY_TITLE = __('Package Registry');

export const PACKAGE_ERROR_STATUS = 'ERROR';
export const PACKAGE_DEFAULT_STATUS = 'DEFAULT';
export const PACKAGE_DEPRECATED_STATUS = 'DEPRECATED';

export const NPM_PACKAGE_MANAGER = 'npm';
export const YARN_PACKAGE_MANAGER = 'yarn';

export const PROJECT_PACKAGE_ENDPOINT_TYPE = 'project';
export const INSTANCE_PACKAGE_ENDPOINT_TYPE = 'instance';

export const GRAPHQL_PAGE_SIZE = 20;

export const LIST_KEY_NAME = 'name';
export const LIST_KEY_PROJECT = 'project_path';
export const LIST_KEY_VERSION = 'version';
export const LIST_KEY_PACKAGE_TYPE = 'type';
export const LIST_KEY_CREATED_AT = 'created_at';

export const LIST_LABEL_NAME = __('Name');
export const LIST_LABEL_PROJECT = __('Project');
export const LIST_LABEL_VERSION = __('Version');
export const LIST_LABEL_PACKAGE_TYPE = __('Type');
export const LIST_LABEL_CREATED_AT = __('Published');

export const SORT_FIELDS = [
  {
    orderBy: LIST_KEY_NAME,
    label: LIST_LABEL_NAME,
  },
  {
    orderBy: LIST_KEY_PROJECT,
    label: LIST_LABEL_PROJECT,
  },
  {
    orderBy: LIST_KEY_VERSION,
    label: LIST_LABEL_VERSION,
  },
  {
    orderBy: LIST_KEY_PACKAGE_TYPE,
    label: LIST_LABEL_PACKAGE_TYPE,
  },
  {
    orderBy: LIST_KEY_CREATED_AT,
    label: LIST_LABEL_CREATED_AT,
  },
];

/* eslint-disable @gitlab/require-i18n-strings */
export const PACKAGE_TYPES_OPTIONS = [
  { value: 'Composer', title: s__('PackageRegistry|Composer') },
  { value: 'Conan', title: s__('PackageRegistry|Conan') },
  { value: 'Generic', title: s__('PackageRegistry|Generic') },
  { value: 'Maven', title: s__('PackageRegistry|Maven') },
  { value: 'npm', title: s__('PackageRegistry|npm') },
  { value: 'NuGet', title: s__('PackageRegistry|NuGet') },
  { value: 'PyPI', title: s__('PackageRegistry|PyPI') },
  { value: 'RubyGems', title: s__('PackageRegistry|RubyGems') },
  { value: 'Debian', title: s__('PackageRegistry|Debian') },
  { value: 'Helm', title: s__('PackageRegistry|Helm') },
  { value: 'Ml_Model', title: s__('PackageRegistry|Machine learning model') },
];
/* eslint-enable @gitlab/require-i18n-strings */

export const PACKAGE_STATUS_OPTIONS = [
  {
    value: PACKAGE_DEFAULT_STATUS.toLowerCase(),
    title: s__('PackageRegistry|Default'),
  },
  { value: PACKAGE_ERROR_STATUS.toLowerCase(), title: s__('PackageRegistry|Error') },
  { value: 'hidden', title: s__('PackageRegistry|Hidden') },
  { value: 'pending_destruction', title: s__('PackageRegistry|Pending deletion') },
  { value: 'processing', title: s__('PackageRegistry|Processing') },
];

// links

export const EMPTY_LIST_HELP_URL = helpPagePath('user/packages/package_registry/_index');
export const PACKAGE_HELP_URL = helpPagePath('user/packages/_index');
export const NPM_HELP_PATH = helpPagePath('user/packages/npm_registry/_index');
export const MAVEN_HELP_PATH = helpPagePath('user/packages/maven_repository/_index');
export const CONAN_HELP_PATH = helpPagePath('user/packages/conan_repository/_index');
export const NUGET_HELP_PATH = helpPagePath('user/packages/nuget_repository/_index');
export const PYPI_HELP_PATH = helpPagePath('user/packages/pypi_repository/_index');
export const COMPOSER_HELP_PATH = helpPagePath('user/packages/composer_repository/_index');
export const PERSONAL_ACCESS_TOKEN_HELP_URL = helpPagePath('user/profile/personal_access_tokens');
export const REQUEST_FORWARDING_HELP_PAGE_PATH = helpPagePath(
  'user/packages/package_registry/supported_functionality',
  { anchor: 'deleting-packages' },
);

export const GRAPHQL_PACKAGE_PIPELINES_PAGE_SIZE = 10;
export const GRAPHQL_PACKAGE_FILES_PAGE_SIZE = 20;
