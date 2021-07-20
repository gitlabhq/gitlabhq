export const PERFORMANCE_TYPE_MARK = 'mark';
export const PERFORMANCE_TYPE_MEASURE = 'measure';

//
// SNIPPET namespace
//

// Marks
export const SNIPPET_MARK_VIEW_APP_START = 'snippet-view-app-start';
export const SNIPPET_MARK_EDIT_APP_START = 'snippet-edit-app-start';
export const SNIPPET_MARK_BLOBS_CONTENT = 'snippet-blobs-content-finished';

// Measures
export const SNIPPET_MEASURE_BLOBS_CONTENT = 'snippet-blobs-content';

//
// WebIDE namespace
//

// Marks
export const WEBIDE_MARK_APP_START = 'webide-app-start';
export const WEBIDE_MARK_FILE_CLICKED = 'webide-file-clicked';
export const WEBIDE_MARK_FILE_FINISH = 'webide-file-finished';
export const WEBIDE_MARK_REPO_EDITOR_START = 'webide-init-editor-start';
export const WEBIDE_MARK_REPO_EDITOR_FINISH = 'webide-init-editor-finish';
export const WEBIDE_MARK_FETCH_BRANCH_DATA_START = 'webide-getBranchData-start';
export const WEBIDE_MARK_FETCH_BRANCH_DATA_FINISH = 'webide-getBranchData-finish';
export const WEBIDE_MARK_FETCH_FILE_DATA_START = 'webide-getFileData-start';
export const WEBIDE_MARK_FETCH_FILE_DATA_FINISH = 'webide-getFileData-finish';
export const WEBIDE_MARK_FETCH_FILES_START = 'webide-getFiles-start';
export const WEBIDE_MARK_FETCH_FILES_FINISH = 'webide-getFiles-finish';
export const WEBIDE_MARK_FETCH_PROJECT_DATA_START = 'webide-getProjectData-start';
export const WEBIDE_MARK_FETCH_PROJECT_DATA_FINISH = 'webide-getProjectData-finish';

// Measures
export const WEBIDE_MEASURE_FILE_AFTER_INTERACTION = 'webide-file-loading-after-interaction';
export const WEBIDE_MEASURE_FETCH_PROJECT_DATA = 'WebIDE: Project data';
export const WEBIDE_MEASURE_FETCH_BRANCH_DATA = 'WebIDE: Branch data';
export const WEBIDE_MEASURE_FETCH_FILE_DATA = 'WebIDE: File data';
export const WEBIDE_MEASURE_BEFORE_VUE = 'WebIDE: Before Vue app';
export const WEBIDE_MEASURE_REPO_EDITOR = 'WebIDE: Repo Editor';
export const WEBIDE_MEASURE_FETCH_FILES = 'WebIDE: Fetch Files';

//
// MR Diffs namespace
//

// Marks
export const MR_DIFFS_MARK_FILE_TREE_START = 'mr-diffs-mark-file-tree-start';
export const MR_DIFFS_MARK_FILE_TREE_END = 'mr-diffs-mark-file-tree-end';
export const MR_DIFFS_MARK_DIFF_FILES_START = 'mr-diffs-mark-diff-files-start';
export const MR_DIFFS_MARK_FIRST_DIFF_FILE_SHOWN = 'mr-diffs-mark-first-diff-file-shown';
export const MR_DIFFS_MARK_DIFF_FILES_END = 'mr-diffs-mark-diff-files-end';

// Measures
export const MR_DIFFS_MEASURE_FILE_TREE_DONE = 'mr-diffs-measure-file-tree-done';
export const MR_DIFFS_MEASURE_DIFF_FILES_DONE = 'mr-diffs-measure-diff-files-done';

//
// Pipelines Detail namespace
//

// Marks
export const PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START =
  'pipelines-detail-links-mark-calculate-start';
export const PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END =
  'pipelines-detail-links-mark-calculate-end';

// Measures
export const PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION =
  'Pipelines Detail Graph: Links Calculation';

// Metrics
// Note: These strings must match the backend
// (defined in: app/services/ci/prometheus_metrics/observe_histograms_service.rb)
export const PIPELINES_DETAIL_LINK_DURATION = 'pipeline_graph_link_calculation_duration_seconds';
export const PIPELINES_DETAIL_LINKS_TOTAL = 'pipeline_graph_links_total';
export const PIPELINES_DETAIL_LINKS_JOB_RATIO = 'pipeline_graph_links_per_job_ratio';

//
// REPO BROWSER NAMESPACE
//

// Marks
export const REPO_BLOB_LOAD_VIEWER_START = 'blobviewer-load-viewer-start';
export const REPO_BLOB_SWITCH_TO_VIEWER_START = 'blobviewer-switch-to-viewerr-start';
export const REPO_BLOB_LOAD_VIEWER_FINISH = 'blobviewer-load-viewer-finish';

// Measures
export const REPO_BLOB_LOAD_VIEWER = 'Repository File Viewer: loading the viewer';
export const REPO_BLOB_SWITCH_VIEWER = 'Repository File Viewer: switching the viewer';

//
// DESIGN MANAGEMENT NAMESPACE
//

// Marks
export const DESIGN_MARK_APP_START = 'design-app-start';

// Measures
export const DESIGN_MEASURE_BEFORE_APP = 'Design Management: Before the Vue app';
export const DESIGN_MAIN_IMAGE_OUTPUT = 'Design Management: Single image preview';
