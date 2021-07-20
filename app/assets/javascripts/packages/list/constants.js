import { __, s__ } from '~/locale';
import { PackageType } from '../shared/constants';

export const FETCH_PACKAGES_LIST_ERROR_MESSAGE = __(
  'Something went wrong while fetching the packages list.',
);
export const FETCH_PACKAGE_ERROR_MESSAGE = __('Something went wrong while fetching the package.');
export const DELETE_PACKAGE_SUCCESS_MESSAGE = __('Package deleted successfully');

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 20;

export const GROUP_PAGE_TYPE = 'groups';

export const LIST_KEY_NAME = 'name';
export const LIST_KEY_PROJECT = 'project_path';
export const LIST_KEY_VERSION = 'version';
export const LIST_KEY_PACKAGE_TYPE = 'type';
export const LIST_KEY_CREATED_AT = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';

export const LIST_LABEL_NAME = __('Name');
export const LIST_LABEL_PROJECT = __('Project');
export const LIST_LABEL_VERSION = __('Version');
export const LIST_LABEL_PACKAGE_TYPE = __('Type');
export const LIST_LABEL_CREATED_AT = __('Published');
export const LIST_LABEL_ACTIONS = '';

// The following is not translated because it is used to build a JavaScript exception error message
export const MISSING_DELETE_PATH_ERROR = 'Missing delete_api_path link';

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

export const PACKAGE_TYPES = [
  {
    title: s__('PackageRegistry|Composer'),
    type: PackageType.COMPOSER,
  },
  {
    title: s__('PackageRegistry|Conan'),
    type: PackageType.CONAN,
  },
  {
    title: s__('PackageRegistry|Generic'),
    type: PackageType.GENERIC,
  },

  {
    title: s__('PackageRegistry|Maven'),
    type: PackageType.MAVEN,
  },
  {
    title: s__('PackageRegistry|npm'),
    type: PackageType.NPM,
  },
  {
    title: s__('PackageRegistry|NuGet'),
    type: PackageType.NUGET,
  },
  {
    title: s__('PackageRegistry|PyPI'),
    type: PackageType.PYPI,
  },
  {
    title: s__('PackageRegistry|RubyGems'),
    type: PackageType.RUBYGEMS,
  },
  {
    title: s__('PackageRegistry|Debian'),
    type: PackageType.DEBIAN,
  },
  {
    title: s__('PackageRegistry|Helm'),
    type: PackageType.HELM,
  },
];

export const LIST_TITLE_TEXT = s__('PackageRegistry|Package Registry');

export const LIST_INTRO_TEXT = s__(
  'PackageRegistry|Publish and share packages for a variety of common package managers. %{docLinkStart}More information%{docLinkEnd}',
);

export const TERRAFORM_SEARCH_TYPE = Object.freeze({ value: { data: 'terraform_module' } });
