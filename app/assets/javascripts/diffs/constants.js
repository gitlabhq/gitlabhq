export const INLINE_DIFF_VIEW_TYPE = 'inline';
export const PARALLEL_DIFF_VIEW_TYPE = 'parallel';
export const MATCH_LINE_TYPE = 'match';
export const OLD_NO_NEW_LINE_TYPE = 'old-nonewline';
export const NEW_NO_NEW_LINE_TYPE = 'new-nonewline';
export const CONTEXT_LINE_TYPE = 'context';
export const EMPTY_CELL_TYPE = 'empty-cell';
export const COMMENT_FORM_TYPE = 'commentForm';
export const DIFF_NOTE_TYPE = 'DiffNote';
export const LEGACY_DIFF_NOTE_TYPE = 'LegacyDiffNote';
export const NOTE_TYPE = 'Note';
export const NEW_LINE_TYPE = 'new';
export const OLD_LINE_TYPE = 'old';
export const TEXT_DIFF_POSITION_TYPE = 'text';
export const IMAGE_DIFF_POSITION_TYPE = 'image';

export const LINE_POSITION_LEFT = 'left';
export const LINE_POSITION_RIGHT = 'right';
export const LINE_SIDE_LEFT = 'left-side';
export const LINE_SIDE_RIGHT = 'right-side';

export const DIFF_VIEW_COOKIE_NAME = 'diff_view';
export const DIFF_WHITESPACE_COOKIE_NAME = 'diff_whitespace';
export const LINE_HOVER_CLASS_NAME = 'is-over';
export const LINE_UNFOLD_CLASS_NAME = 'unfold js-unfold';
export const CONTEXT_LINE_CLASS_NAME = 'diff-expanded';

export const UNFOLD_COUNT = 20;
export const COUNT_OF_AVATARS_IN_GUTTER = 3;
export const LENGTH_OF_AVATAR_TOOLTIP = 17;

export const LINES_TO_BE_RENDERED_DIRECTLY = 100;

export const DIFF_FILE_SYMLINK_MODE = '120000';
export const DIFF_FILE_DELETED_MODE = '0';

export const MR_TREE_SHOW_KEY = 'mr_tree_show';

export const TREE_TYPE = 'tree';
export const TREE_LIST_STORAGE_KEY = 'mr_diff_tree_list';
export const TREE_LIST_WIDTH_STORAGE_KEY = 'mr_tree_list_width';

export const INITIAL_TREE_WIDTH = 320;
export const MIN_TREE_WIDTH = 240;
export const MAX_TREE_WIDTH = 400;
export const TREE_HIDE_STATS_WIDTH = 260;

export const OLD_LINE_KEY = 'old_line';
export const NEW_LINE_KEY = 'new_line';
export const TYPE_KEY = 'type';
export const LEFT_LINE_KEY = 'left';

export const CENTERED_LIMITED_CONTAINER_CLASSES =
  'container-limited limit-container-width mx-lg-auto px-3';

export const MAX_RENDERING_DIFF_LINES = 500;
export const MAX_RENDERING_BULK_ROWS = 30;
export const MIN_RENDERING_MS = 2;
export const START_RENDERING_INDEX = 200;
export const INLINE_DIFF_LINES_KEY = 'highlighted_diff_lines';
export const PARALLEL_DIFF_LINES_KEY = 'parallel_diff_lines';

export const DIFF_COMPARE_BASE_VERSION_INDEX = -1;
export const DIFF_COMPARE_HEAD_VERSION_INDEX = -2;

// Diff View Alerts
export const ALERT_OVERFLOW_HIDDEN = 'overflow';
export const ALERT_MERGE_CONFLICT = 'merge-conflict';
export const ALERT_COLLAPSED_FILES = 'collapsed';

// Diff File collapse types
export const DIFF_FILE_AUTOMATIC_COLLAPSE = 'automatic';
export const DIFF_FILE_MANUAL_COLLAPSE = 'manual';

// Diff view single file mode
export const DIFF_FILE_BY_FILE_COOKIE_NAME = 'fileViewMode';
export const DIFF_VIEW_FILE_BY_FILE = 'single';
export const DIFF_VIEW_ALL_FILES = 'all';

// State machine states
export const STATE_IDLING = 'idle';
export const STATE_LOADING = 'loading';
export const STATE_ERRORED = 'errored';

// State machine transitions
export const TRANSITION_LOAD_START = 'LOAD_START';
export const TRANSITION_LOAD_ERROR = 'LOAD_ERROR';
export const TRANSITION_LOAD_SUCCEED = 'LOAD_SUCCEED';
export const TRANSITION_ACKNOWLEDGE_ERROR = 'ACKNOWLEDGE_ERROR';

export const RENAMED_DIFF_TRANSITIONS = {
  [`${STATE_IDLING}:${TRANSITION_LOAD_START}`]: STATE_LOADING,
  [`${STATE_LOADING}:${TRANSITION_LOAD_ERROR}`]: STATE_ERRORED,
  [`${STATE_LOADING}:${TRANSITION_LOAD_SUCCEED}`]: STATE_IDLING,
  [`${STATE_ERRORED}:${TRANSITION_LOAD_START}`]: STATE_LOADING,
  [`${STATE_ERRORED}:${TRANSITION_ACKNOWLEDGE_ERROR}`]: STATE_IDLING,
};

// MR Diffs known events
export const EVT_EXPAND_ALL_FILES = 'mr:diffs:expandAllFiles';
export const EVT_PERF_MARK_FILE_TREE_START = 'mr:diffs:perf:fileTreeStart';
export const EVT_PERF_MARK_FILE_TREE_END = 'mr:diffs:perf:fileTreeEnd';
export const EVT_PERF_MARK_DIFF_FILES_START = 'mr:diffs:perf:filesStart';
export const EVT_PERF_MARK_FIRST_DIFF_FILE_SHOWN = 'mr:diffs:perf:firstFileShown';
export const EVT_PERF_MARK_DIFF_FILES_END = 'mr:diffs:perf:filesEnd';

export const CONFLICT_OUR = 'conflict_our';
export const CONFLICT_THEIR = 'conflict_their';
export const CONFLICT_MARKER = 'conflict_marker';
export const CONFLICT_MARKER_OUR = 'conflict_marker_our';
export const CONFLICT_MARKER_THEIR = 'conflict_marker_their';

// Tracking events
export const TRACKING_CLICK_DIFF_VIEW_SETTING = 'i_code_review_click_diff_view_setting';
export const TRACKING_DIFF_VIEW_INLINE = 'i_code_review_diff_view_inline';
export const TRACKING_DIFF_VIEW_PARALLEL = 'i_code_review_diff_view_parallel';

export const TRACKING_CLICK_FILE_BROWSER_SETTING = 'i_code_review_click_file_browser_setting';
export const TRACKING_FILE_BROWSER_TREE = 'i_code_review_file_browser_tree_view';
export const TRACKING_FILE_BROWSER_LIST = 'i_code_review_file_browser_list_view';

export const TRACKING_CLICK_WHITESPACE_SETTING = 'i_code_review_click_whitespace_setting';
export const TRACKING_WHITESPACE_SHOW = 'i_code_review_diff_show_whitespace';
export const TRACKING_WHITESPACE_HIDE = 'i_code_review_diff_hide_whitespace';

export const TRACKING_CLICK_SINGLE_FILE_SETTING = 'i_code_review_click_single_file_mode_setting';
export const TRACKING_SINGLE_FILE_MODE = 'i_code_review_diff_single_file';
export const TRACKING_MULTIPLE_FILES_MODE = 'i_code_review_diff_multiple_files';
