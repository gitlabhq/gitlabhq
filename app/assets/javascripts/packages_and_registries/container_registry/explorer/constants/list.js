import { s__, __ } from '~/locale';
import { NAME_SORT_FIELD } from './common';

//  Translations strings

export const CONTAINER_REGISTRY_TITLE = s__('ContainerRegistry|Container Registry');
export const SETTINGS_TEXT = s__('ContainerRegistry|Configure in settings');
export const CONNECTION_ERROR_TITLE = s__('ContainerRegistry|Docker connection error');
export const CONNECTION_ERROR_MESSAGE = s__(
  `ContainerRegistry|We are having trouble connecting to the Container Registry. Please try refreshing the page. If this error persists, please review %{docLinkStart}the troubleshooting documentation%{docLinkEnd}.`,
);
export const LIST_DELETE_BUTTON_DISABLED = s__(
  'ContainerRegistry|Missing or insufficient permission, delete button disabled',
);
export const LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION = s__(
  `ContainerRegistry|Image repository temporarily cannot be marked for deletion. Please try again in a few minutes. %{docLinkStart}More details%{docLinkEnd}`,
);
export const REMOVE_REPOSITORY_LABEL = s__('ContainerRegistry|Remove repository');
export const ROW_SCHEDULED_FOR_DELETION = s__(
  `ContainerRegistry|This image repository is scheduled for deletion`,
);
export const FETCH_IMAGES_LIST_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the repository list.',
);
export const DELETE_IMAGE_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while scheduling %{title} for deletion. Please try again.',
);
export const DELETE_IMAGE_SUCCESS_MESSAGE = s__(
  'ContainerRegistry|%{title} was successfully scheduled for deletion',
);
export const EMPTY_RESULT_TITLE = s__('ContainerRegistry|Sorry, your filter produced no results.');
export const EMPTY_RESULT_MESSAGE = s__(
  'ContainerRegistry|To widen your search, change or remove the filters above.',
);
export const SIGNATURE_BADGE_TOOLTIP = s__(
  'ContainerRegistry|GitLab is unable to validate this signature automatically. Validate the signature manually before trusting it.',
);

export const COPY_IMAGE_PATH_TITLE = s__('ContainerRegistry|Copy image path');

export const IMAGE_FULL_PATH_LABEL = s__('ContainerRegistry|Show full path');

// Tracking

export const TRACKING_LABEL_REGISTRY_IMAGE_LIST = 'registry_image_list';
export const TRACKING_ACTION_CLICK_SHOW_FULL_PATH = 'click_show_full_path';

// Parameters

export const IMAGE_DELETE_SCHEDULED_STATUS = 'DELETE_SCHEDULED';
export const IMAGE_MIGRATING_STATE = 'importing';
export const GRAPHQL_PAGE_SIZE = 10;
export const GRAPHQL_PAGE_SIZE_METADATA_ENABLED = 20;

export const SORT_FIELDS = [
  { orderBy: 'UPDATED', label: __('Updated') },
  { orderBy: 'CREATED', label: __('Created') },
  NAME_SORT_FIELD,
];
