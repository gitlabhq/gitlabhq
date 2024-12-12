import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, sprintf } from '~/locale';

export const BTN_COPY_CONTENTS_TITLE = __('Copy file contents');
export const BTN_RAW_TITLE = __('Open raw');
export const BTN_DOWNLOAD_TITLE = __('Download');

export const SIMPLE_BLOB_VIEWER = 'simple';
export const SIMPLE_BLOB_VIEWER_TITLE = __('Display source');
export const SIMPLE_BLOB_VIEWER_LABEL = __('Code');

export const RICH_BLOB_VIEWER = 'rich';
export const RICH_BLOB_VIEWER_TITLE = __('Display rendered file');
export const RICH_BLOB_VIEWER_LABEL = __('Preview');

export const BLAME_VIEWER = 'blame';
export const BLAME_TITLE = __('Display blame info');

export const BLOB_RENDER_EVENT_LOAD = 'force-content-fetch';
export const BLOB_RENDER_EVENT_SHOW_SOURCE = 'force-switch-viewer';

export const BLOB_RENDER_ERRORS = {
  REASONS: {
    COLLAPSED: {
      id: 'collapsed',
      text: sprintf(__('it is larger than %{limit}'), {
        limit: numberToHumanSize(1048576), // 1MB in bytes
      }),
    },
    TOO_LARGE: {
      id: 'too_large',
      text: sprintf(__('it is larger than %{limit}'), {
        limit: numberToHumanSize(10485760), // 10MB in bytes
      }),
    },
    EXTERNAL: {
      id: 'server_side_but_stored_externally',
      text: {
        lfs: __('it is stored in LFS'),
        build_artifact: __('it is stored as a job artifact'),
        default: __('it is stored externally'),
      },
    },
  },
  OPTIONS: {
    LOAD: {
      id: 'load',
      text: __('load it anyway'),
      conjunction: __('or'),
      href: '?expanded=true&viewer=simple',
      target: '',
      event: BLOB_RENDER_EVENT_LOAD,
    },
    SHOW_SOURCE: {
      id: 'show_source',
      text: __('view the source'),
      conjunction: __('or'),
      href: '#',
      target: '',
      event: BLOB_RENDER_EVENT_SHOW_SOURCE,
    },
    DOWNLOAD: {
      id: 'download',
      text: __('download it'),
      conjunction: '',
      target: '_blank',
      condition: true,
    },
  },
};
