import { __, s__ } from '~/locale';
import { PackageType } from '../shared/constants';

export const FETCH_PACKAGES_LIST_ERROR_MESSAGE = __(
  'Something went wrong while fetching the packages list.',
);
export const FETCH_PACKAGE_ERROR_MESSAGE = __('Something went wrong while fetching the package.');
export const DELETE_PACKAGE_ERROR_MESSAGE = __('Something went wrong while deleting the package.');
export const DELETE_PACKAGE_SUCCESS_MESSAGE = __('Package deleted successfully');

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 20;

export const GROUP_PAGE_TYPE = 'groups';

export const LIST_KEY_NAME = 'name';
export const LIST_KEY_PROJECT = 'project_path';
export const LIST_KEY_VERSION = 'version';
export const LIST_KEY_PACKAGE_TYPE = 'package_type';
export const LIST_KEY_CREATED_AT = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';

export const LIST_LABEL_NAME = __('Name');
export const LIST_LABEL_PROJECT = __('Project');
export const LIST_LABEL_VERSION = __('Version');
export const LIST_LABEL_PACKAGE_TYPE = __('Type');
export const LIST_LABEL_CREATED_AT = __('Created');
export const LIST_LABEL_ACTIONS = '';

export const LIST_ORDER_BY_PACKAGE_TYPE = 'type';

export const ASCENDING_ODER = 'asc';
export const DESCENDING_ORDER = 'desc';

// The following is not translated because it is used to build a JavaScript exception error message
export const MISSING_DELETE_PATH_ERROR = 'Missing delete_api_path link';

export const TABLE_HEADER_FIELDS = [
  {
    key: LIST_KEY_NAME,
    label: LIST_LABEL_NAME,
    orderBy: LIST_KEY_NAME,
    class: ['text-left'],
  },
  {
    key: LIST_KEY_PROJECT,
    label: LIST_LABEL_PROJECT,
    orderBy: LIST_KEY_PROJECT,
    class: ['text-left'],
  },
  {
    key: LIST_KEY_VERSION,
    label: LIST_LABEL_VERSION,
    orderBy: LIST_KEY_VERSION,
    class: ['text-center'],
  },
  {
    key: LIST_KEY_PACKAGE_TYPE,
    label: LIST_LABEL_PACKAGE_TYPE,
    orderBy: LIST_ORDER_BY_PACKAGE_TYPE,
    class: ['text-center'],
  },
  {
    key: LIST_KEY_CREATED_AT,
    label: LIST_LABEL_CREATED_AT,
    orderBy: LIST_KEY_CREATED_AT,
    class: ['text-center'],
  },
];

export const PACKAGE_REGISTRY_TABS = [
  {
    title: __('All'),
    type: null,
  },
  {
    title: s__('PackageRegistry|Conan'),
    type: PackageType.CONAN,
  },
  {
    title: s__('PackageRegistry|Maven'),
    type: PackageType.MAVEN,
  },
  {
    title: s__('PackageRegistry|NPM'),
    type: PackageType.NPM,
  },
  {
    title: s__('PackageRegistry|NuGet'),
    type: PackageType.NUGET,
  },
  {
    title: s__('PackageRegistry|PyPi'),
    type: PackageType.PYPI,
  },
];
