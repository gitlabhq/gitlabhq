import { s__ } from '~/locale';

export const HISTORY_PIPELINES_LIMIT = 5;

export const DELETE_PACKAGE_TRACKING_ACTION = 'delete_package';
export const REQUEST_DELETE_PACKAGE_TRACKING_ACTION = 'request_delete_package';
export const CANCEL_DELETE_PACKAGE_TRACKING_ACTION = 'cancel_delete_package';
export const PULL_PACKAGE_TRACKING_ACTION = 'pull_package';
export const DELETE_PACKAGE_FILE_TRACKING_ACTION = 'delete_package_file';
export const DELETE_PACKAGE_FILES_TRACKING_ACTION = 'delete_package_files';
export const SELECT_PACKAGE_FILE_TRACKING_ACTION = 'select_package_file';
export const REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'request_delete_package_file';
export const REQUEST_DELETE_SELECTED_PACKAGE_FILE_TRACKING_ACTION =
  'request_delete_selected_package_file';
export const CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION = 'cancel_delete_package_file';
export const DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION = 'download_package_asset';

export const TRACKING_ACTIONS = {
  DELETE_PACKAGE: DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE: REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE: CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  PULL_PACKAGE: PULL_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGE_FILE: DELETE_PACKAGE_FILE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_FILE: REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_FILE: CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  DOWNLOAD_PACKAGE_ASSET: DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
};

export const SHOW_DELETE_SUCCESS_ALERT = 'showSuccessDeleteAlert';
export const DELETE_PACKAGE_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package.',
);
export const DELETE_PACKAGE_FILE_ERROR_MESSAGE = s__(
  'PackageRegistry|Something went wrong while deleting the package asset.',
);
export const DELETE_PACKAGE_FILE_SUCCESS_MESSAGE = s__(
  'PackageRegistry|Package asset deleted successfully',
);

export const DELETE_PACKAGE_MODAL_CONTENT_MESSAGE = s__(
  'PackageRegistry|You are about to delete %{name}, are you sure?',
);
export const DELETE_PACKAGE_MODAL_TITLE = s__('PackageRegistry|Delete package');
export const DELETE_PACKAGE_MODAL_ACTION = s__('PackageRegistry|Permanently delete');

export const PACKAGE_ERROR_STATUS = 'error';
export const PACKAGE_DEFAULT_STATUS = 'default';
export const PACKAGE_HIDDEN_STATUS = 'hidden';
export const PACKAGE_PROCESSING_STATUS = 'processing';
