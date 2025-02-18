import { __, s__, n__, sprintf } from '~/locale';

export const PAGE_TITLE = s__('Artifacts|Artifacts');
export const TOTAL_ARTIFACTS_SIZE = s__('Artifacts|Total artifacts size');
export const SIZE_UNKNOWN = __('Unknown');

export const I18N_DOWNLOAD = __('Download');
export const I18N_CHECKBOX = __('Select artifacts');
export const I18N_BROWSE = s__('Artifacts|Browse');
export const I18N_DELETE = __('Delete');
export const I18N_EXPIRED = __('Expired');
export const I18N_DESTROY_ERROR = s__('Artifacts|An error occurred while deleting the artifact');
export const I18N_FETCH_ERROR = s__('Artifacts|An error occurred while retrieving job artifacts');
export const I18N_ARTIFACTS = __('Artifacts');
export const I18N_JOB = __('Job');
export const I18N_SIZE = __('Size');
export const I18N_CREATED = __('Created');
export const I18N_ARTIFACTS_COUNT = (count) => n__('%d file', '%d files', count);

export const I18N_MODAL_TITLE = (artifactName) =>
  sprintf(s__('Artifacts|Delete %{name}?'), { name: artifactName });
export const I18N_MODAL_BODY = s__(
  'Artifacts|This artifact will be permanently deleted. Any reports generated from this artifact will be empty.',
);
export const I18N_MODAL_PRIMARY = s__('Artifacts|Delete artifact');
export const I18N_MODAL_CANCEL = __('Cancel');

export const I18N_BULK_DELETE_MAX_SELECTED = s__(
  'Artifacts|Maximum selected artifacts limit reached',
);
export const I18N_BULK_DELETE_BANNER = (count) =>
  sprintf(
    n__(
      'Artifacts|%{strongStart}%{count}%{strongEnd} artifact selected',
      'Artifacts|%{strongStart}%{count}%{strongEnd} artifacts selected',
      count,
    ),
    {
      count,
    },
  );
export const I18N_BULK_DELETE_CLEAR_SELECTION = s__('Artifacts|Clear selection');
export const I18N_BULK_DELETE_DELETE_SELECTED = s__('Artifacts|Delete selected');

export const BULK_DELETE_MODAL_ID = 'artifacts-bulk-delete-modal';
export const I18N_BULK_DELETE_MODAL_TITLE = (count) =>
  n__('Artifacts|Delete %d artifact?', 'Artifacts|Delete %d artifacts?', count);
export const I18N_BULK_DELETE_BODY = (count) =>
  sprintf(
    n__(
      'Artifacts|The selected artifact will be permanently deleted. Any reports generated from these artifacts will be empty.',
      'Artifacts|The selected artifacts will be permanently deleted. Any reports generated from these artifacts will be empty.',
      count,
    ),
    { count },
  );
export const I18N_BULK_DELETE_ACTION = (count) =>
  n__('Artifacts|Delete %d artifact', 'Artifacts|Delete %d artifacts', count);

export const I18N_BULK_DELETE_PARTIAL_ERROR = s__(
  'Artifacts|An error occurred while deleting. Some artifacts may not have been deleted.',
);
export const I18N_BULK_DELETE_ERROR = s__(
  'Artifacts|Something went wrong while deleting. Please refresh the page to try again.',
);
export const I18N_BULK_DELETE_CONFIRMATION_TOAST = (count) =>
  n__('Artifacts|%d selected artifact deleted', 'Artifacts|%d selected artifacts deleted', count);

export const INITIAL_CURRENT_PAGE = 1;
export const INITIAL_PREVIOUS_PAGE_CURSOR = '';
export const INITIAL_NEXT_PAGE_CURSOR = '';
export const JOBS_PER_PAGE = 20;
export const INITIAL_LAST_PAGE_SIZE = null;

export const ARCHIVE_FILE_TYPE = 'ARCHIVE';
export const METADATA_FILE_TYPE = 'METADATA';

export const ARTIFACT_ROW_HEIGHT = 56;
export const ARTIFACTS_SHOWN_WITHOUT_SCROLLING = 4;
