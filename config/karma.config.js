const path = require('path');
const glob = require('glob');
const chalk = require('chalk');
const webpack = require('webpack');
const argumentsParser = require('commander');
const escapeRegex = require('escape-string-regexp');
const webpackConfig = require('./webpack.config.js');

const ROOT_PATH = path.resolve(__dirname, '..');
const TEST_CONTEXT_PATH = 'spec/javascripts';
const CODE_CONTEXT_PATH = 'app/assets/javascripts';

function fatalError(message) {
  console.error(chalk.red(`\nError: ${message}\n`));
  process.exit(1);
}

// disable problematic options
webpackConfig.entry = undefined;
webpackConfig.mode = 'development';
webpackConfig.optimization.nodeEnv = false;
webpackConfig.optimization.runtimeChunk = false;
webpackConfig.optimization.splitChunks = false;

// use quicker sourcemap option
webpackConfig.devtool = 'cheap-inline-source-map';

const specFilters = argumentsParser
  .option(
    '-f, --filter-spec [filter]',
    'Filter run spec files by path. Multiple filters are like a logical OR.',
    (filter, memo) => {
      memo.push(filter, filter.replace(/\/?$/, '/**/*.js'));
      return memo;
    },
    []
  )
  .parse(process.argv).filterSpec;

function createContext(root, globs) {
  const context = {};
  let specFilePaths = []
    .concat(globs)
    .map(filter =>
      glob.sync(filter, { root, matchBase: true }).filter(path => path.endsWith('spec.js'))
    );

  // flatten results
  specFilePaths = Array.prototype.concat.apply([], specFilePaths);

  // remove duplicates
  specFilePaths = [...new Set(specFilePaths)];

  // generate context relative to root
  specFilePaths.forEach(file => (context[file] = path.join(root, file)));
  return context;
}

console.log(`Locating tests files...`);

const testContext = {
  './spec/javascripts/activities_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/activities_spec.js',
  './spec/javascripts/ajax_loading_spinner_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ajax_loading_spinner_spec.js',
  './spec/javascripts/api_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/api_spec.js',
  './spec/javascripts/autosave_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/autosave_spec.js',
  './spec/javascripts/avatar_helper_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/avatar_helper_spec.js',
  './spec/javascripts/awards_handler_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/awards_handler_spec.js',
  './spec/javascripts/badges/components/badge_form_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/components/badge_form_spec.js',
  './spec/javascripts/badges/components/badge_list_row_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/components/badge_list_row_spec.js',
  './spec/javascripts/badges/components/badge_list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/components/badge_list_spec.js',
  './spec/javascripts/badges/components/badge_settings_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/components/badge_settings_spec.js',
  './spec/javascripts/badges/components/badge_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/components/badge_spec.js',
  './spec/javascripts/badges/store/actions_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/store/actions_spec.js',
  './spec/javascripts/badges/store/mutations_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/badges/store/mutations_spec.js',
  './spec/javascripts/behaviors/autosize_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/autosize_spec.js',
  './spec/javascripts/behaviors/bind_in_out_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/bind_in_out_spec.js',
  './spec/javascripts/behaviors/copy_as_gfm_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/copy_as_gfm_spec.js',
  './spec/javascripts/behaviors/gl_emoji/unicode_support_map_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/gl_emoji/unicode_support_map_spec.js',
  './spec/javascripts/behaviors/quick_submit_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/quick_submit_spec.js',
  './spec/javascripts/behaviors/requires_input_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/requires_input_spec.js',
  './spec/javascripts/behaviors/secret_values_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/behaviors/secret_values_spec.js',
  './spec/javascripts/blob/3d_viewer/mesh_object_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/3d_viewer/mesh_object_spec.js',
  './spec/javascripts/blob/balsamiq/balsamiq_viewer_integration_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/balsamiq/balsamiq_viewer_integration_spec.js',
  './spec/javascripts/blob/balsamiq/balsamiq_viewer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/balsamiq/balsamiq_viewer_spec.js',
  './spec/javascripts/blob/blob_file_dropzone_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/blob_file_dropzone_spec.js',
  './spec/javascripts/blob/blob_fork_suggestion_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/blob_fork_suggestion_spec.js',
  './spec/javascripts/blob/notebook/index_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/notebook/index_spec.js',
  './spec/javascripts/blob/pdf/index_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/pdf/index_spec.js',
  './spec/javascripts/blob/sketch/index_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/sketch/index_spec.js',
  './spec/javascripts/blob/viewer/index_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/blob/viewer/index_spec.js',
  './spec/javascripts/boards/board_blank_state_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/board_blank_state_spec.js',
  './spec/javascripts/boards/board_card_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/board_card_spec.js',
  './spec/javascripts/boards/board_list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/board_list_spec.js',
  './spec/javascripts/boards/board_new_issue_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/board_new_issue_spec.js',
  './spec/javascripts/boards/boards_store_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/boards_store_spec.js',
  './spec/javascripts/boards/components/board_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/components/board_spec.js',
  './spec/javascripts/boards/issue_card_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/issue_card_spec.js',
  './spec/javascripts/boards/issue_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/issue_spec.js',
  './spec/javascripts/boards/list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/list_spec.js',
  './spec/javascripts/boards/modal_store_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/modal_store_spec.js',
  './spec/javascripts/boards/utils/query_data_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/boards/utils/query_data_spec.js',
  './spec/javascripts/bootstrap_jquery_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/bootstrap_jquery_spec.js',
  './spec/javascripts/bootstrap_linked_tabs_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/bootstrap_linked_tabs_spec.js',
  './spec/javascripts/branches/branches_delete_modal_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/branches/branches_delete_modal_spec.js',
  './spec/javascripts/breakpoints_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/breakpoints_spec.js',
  './spec/javascripts/ci_variable_list/ajax_variable_list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ci_variable_list/ajax_variable_list_spec.js',
  './spec/javascripts/ci_variable_list/ci_variable_list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ci_variable_list/ci_variable_list_spec.js',
  './spec/javascripts/ci_variable_list/native_form_variable_list_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ci_variable_list/native_form_variable_list_spec.js',
  './spec/javascripts/close_reopen_report_toggle_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/close_reopen_report_toggle_spec.js',
  './spec/javascripts/clusters/clusters_bundle_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/clusters/clusters_bundle_spec.js',
  './spec/javascripts/clusters/components/application_row_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/clusters/components/application_row_spec.js',
  './spec/javascripts/clusters/components/applications_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/clusters/components/applications_spec.js',
  './spec/javascripts/clusters/stores/clusters_store_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/clusters/stores/clusters_store_spec.js',
  './spec/javascripts/collapsed_sidebar_todo_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/collapsed_sidebar_todo_spec.js',
  './spec/javascripts/comment_type_toggle_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/comment_type_toggle_spec.js',
  './spec/javascripts/commit_merge_requests_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/commit_merge_requests_spec.js',
  './spec/javascripts/commit/commit_pipeline_status_component_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/commit/commit_pipeline_status_component_spec.js',
  './spec/javascripts/commit/pipelines/pipelines_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/commit/pipelines/pipelines_spec.js',
  './spec/javascripts/commits_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/commits_spec.js',
  './spec/javascripts/create_item_dropdown_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/create_item_dropdown_spec.js',
  './spec/javascripts/create_merge_request_dropdown_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/create_merge_request_dropdown_spec.js',
  './spec/javascripts/cycle_analytics/banner_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/cycle_analytics/banner_spec.js',
  './spec/javascripts/cycle_analytics/limit_warning_component_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/cycle_analytics/limit_warning_component_spec.js',
  './spec/javascripts/cycle_analytics/total_time_component_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/cycle_analytics/total_time_component_spec.js',
  './spec/javascripts/datetime_utility_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/datetime_utility_spec.js',
  './spec/javascripts/deploy_keys/components/action_btn_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/deploy_keys/components/action_btn_spec.js',
  './spec/javascripts/deploy_keys/components/app_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/deploy_keys/components/app_spec.js',
  './spec/javascripts/deploy_keys/components/key_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/deploy_keys/components/key_spec.js',
  './spec/javascripts/deploy_keys/components/keys_panel_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/deploy_keys/components/keys_panel_spec.js',
  './spec/javascripts/diff_comments_store_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diff_comments_store_spec.js',
  './spec/javascripts/diffs/components/app_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/app_spec.js',
  './spec/javascripts/diffs/components/changed_files_dropdown_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/changed_files_dropdown_spec.js',
  './spec/javascripts/diffs/components/changed_files_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/changed_files_spec.js',
  './spec/javascripts/diffs/components/compare_versions_dropdown_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/compare_versions_dropdown_spec.js',
  './spec/javascripts/diffs/components/compare_versions_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/compare_versions_spec.js',
  './spec/javascripts/diffs/components/diff_content_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_content_spec.js',
  './spec/javascripts/diffs/components/diff_discussions_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_discussions_spec.js',
  './spec/javascripts/diffs/components/diff_file_header_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_file_header_spec.js',
  './spec/javascripts/diffs/components/diff_file_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_file_spec.js',
  './spec/javascripts/diffs/components/diff_gutter_avatars_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_gutter_avatars_spec.js',
  './spec/javascripts/diffs/components/diff_line_gutter_content_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_line_gutter_content_spec.js',
  './spec/javascripts/diffs/components/diff_line_note_form_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/diff_line_note_form_spec.js',
  './spec/javascripts/diffs/components/edit_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/edit_button_spec.js',
  './spec/javascripts/diffs/components/hidden_files_warning_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/hidden_files_warning_spec.js',
  './spec/javascripts/diffs/components/inline_diff_view_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/inline_diff_view_spec.js',
  './spec/javascripts/diffs/components/no_changes_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/no_changes_spec.js',
  './spec/javascripts/diffs/components/parallel_diff_view_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/components/parallel_diff_view_spec.js',
  './spec/javascripts/diffs/store/actions_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/store/actions_spec.js',
  './spec/javascripts/diffs/store/getters_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/store/getters_spec.js',
  './spec/javascripts/diffs/store/mutations_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/store/mutations_spec.js',
  './spec/javascripts/diffs/store/utils_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/diffs/store/utils_spec.js',
  './spec/javascripts/droplab/constants_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/constants_spec.js',
  './spec/javascripts/droplab/drop_down_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/drop_down_spec.js',
  './spec/javascripts/droplab/hook_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/hook_spec.js',
  './spec/javascripts/droplab/plugins/ajax_filter_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/plugins/ajax_filter_spec.js',
  './spec/javascripts/droplab/plugins/ajax_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/plugins/ajax_spec.js',
  './spec/javascripts/droplab/plugins/input_setter_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/droplab/plugins/input_setter_spec.js',
  './spec/javascripts/emoji_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/emoji_spec.js',
  './spec/javascripts/environments/emtpy_state_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/emtpy_state_spec.js',
  './spec/javascripts/environments/environment_actions_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_actions_spec.js',
  './spec/javascripts/environments/environment_external_url_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_external_url_spec.js',
  './spec/javascripts/environments/environment_item_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_item_spec.js',
  './spec/javascripts/environments/environment_monitoring_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_monitoring_spec.js',
  './spec/javascripts/environments/environment_rollback_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_rollback_spec.js',
  // './spec/javascripts/environments/environment_stop_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_stop_spec.js',
  // './spec/javascripts/environments/environment_table_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_table_spec.js',
  // './spec/javascripts/environments/environment_terminal_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environment_terminal_button_spec.js',
  // './spec/javascripts/environments/environments_app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environments_app_spec.js',
  // './spec/javascripts/environments/environments_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/environments_store_spec.js',
  // './spec/javascripts/environments/folder/environments_folder_view_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/environments/folder/environments_folder_view_spec.js',
  // './spec/javascripts/feature_highlight/feature_highlight_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/feature_highlight/feature_highlight_helper_spec.js',
  // './spec/javascripts/feature_highlight/feature_highlight_options_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/feature_highlight/feature_highlight_options_spec.js',
  // './spec/javascripts/feature_highlight/feature_highlight_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/feature_highlight/feature_highlight_spec.js',
  // './spec/javascripts/filtered_search/components/recent_searches_dropdown_content_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/components/recent_searches_dropdown_content_spec.js',
  // './spec/javascripts/filtered_search/dropdown_user_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/dropdown_user_spec.js',
  // './spec/javascripts/filtered_search/dropdown_utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/dropdown_utils_spec.js',
  // './spec/javascripts/filtered_search/filtered_search_dropdown_manager_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/filtered_search_dropdown_manager_spec.js',
  // './spec/javascripts/filtered_search/filtered_search_manager_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/filtered_search_manager_spec.js',
  // './spec/javascripts/filtered_search/filtered_search_token_keys_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/filtered_search_token_keys_spec.js',
  // './spec/javascripts/filtered_search/filtered_search_tokenizer_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/filtered_search_tokenizer_spec.js',
  // './spec/javascripts/filtered_search/filtered_search_visual_tokens_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/filtered_search_visual_tokens_spec.js',
  // './spec/javascripts/filtered_search/recent_searches_root_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/recent_searches_root_spec.js',
  // './spec/javascripts/filtered_search/services/recent_searches_service_error_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/services/recent_searches_service_error_spec.js',
  // './spec/javascripts/filtered_search/services/recent_searches_service_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/services/recent_searches_service_spec.js',
  // './spec/javascripts/filtered_search/stores/recent_searches_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/filtered_search/stores/recent_searches_store_spec.js',
  // './spec/javascripts/flash_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/flash_spec.js',
  // './spec/javascripts/fly_out_nav_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/fly_out_nav_spec.js',
  // './spec/javascripts/frequent_items/components/app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/components/app_spec.js',
  // './spec/javascripts/frequent_items/components/frequent_items_list_item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/components/frequent_items_list_item_spec.js',
  // './spec/javascripts/frequent_items/components/frequent_items_list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/components/frequent_items_list_spec.js',
  // './spec/javascripts/frequent_items/components/frequent_items_search_input_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/components/frequent_items_search_input_spec.js',
  // './spec/javascripts/frequent_items/store/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/store/actions_spec.js',
  // './spec/javascripts/frequent_items/store/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/store/getters_spec.js',
  // './spec/javascripts/frequent_items/store/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/store/mutations_spec.js',
  // './spec/javascripts/frequent_items/utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/frequent_items/utils_spec.js',
  // './spec/javascripts/gfm_auto_complete_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/gfm_auto_complete_spec.js',
  // './spec/javascripts/gl_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/gl_dropdown_spec.js',
  // './spec/javascripts/gl_field_errors_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/gl_field_errors_spec.js',
  // './spec/javascripts/gl_form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/gl_form_spec.js',
  // './spec/javascripts/gpg_badges_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/gpg_badges_spec.js',
  // './spec/javascripts/graphs/stat_graph_contributors_graph_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/graphs/stat_graph_contributors_graph_spec.js',
  // './spec/javascripts/graphs/stat_graph_contributors_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/graphs/stat_graph_contributors_spec.js',
  // './spec/javascripts/graphs/stat_graph_contributors_util_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/graphs/stat_graph_contributors_util_spec.js',
  // './spec/javascripts/groups/components/app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/app_spec.js',
  // './spec/javascripts/groups/components/group_folder_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/group_folder_spec.js',
  // './spec/javascripts/groups/components/group_item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/group_item_spec.js',
  // './spec/javascripts/groups/components/groups_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/groups_spec.js',
  // './spec/javascripts/groups/components/item_actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/item_actions_spec.js',
  // './spec/javascripts/groups/components/item_caret_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/item_caret_spec.js',
  // './spec/javascripts/groups/components/item_stats_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/item_stats_spec.js',
  // './spec/javascripts/groups/components/item_stats_value_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/item_stats_value_spec.js',
  // './spec/javascripts/groups/components/item_type_icon_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/components/item_type_icon_spec.js',
  // './spec/javascripts/groups/service/groups_service_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/service/groups_service_spec.js',
  // './spec/javascripts/groups/store/groups_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/groups/store/groups_store_spec.js',
  // './spec/javascripts/header_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/header_spec.js',
  // './spec/javascripts/helpers/class_spec_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/helpers/class_spec_helper_spec.js',
  // './spec/javascripts/helpers/vuex_action_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/helpers/vuex_action_helper_spec.js',
  // './spec/javascripts/ide/components/activity_bar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/activity_bar_spec.js',
  // './spec/javascripts/ide/components/branches/item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/branches/item_spec.js',
  // './spec/javascripts/ide/components/branches/search_list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/branches/search_list_spec.js',
  // './spec/javascripts/ide/components/changed_file_icon_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/changed_file_icon_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/actions_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/empty_state_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/empty_state_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/form_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/list_collapsed_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/list_collapsed_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/list_item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/list_item_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/list_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/message_field_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/message_field_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/radio_group_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/radio_group_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/stage_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/stage_button_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/success_message_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/success_message_spec.js',
  // './spec/javascripts/ide/components/commit_sidebar/unstage_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/commit_sidebar/unstage_button_spec.js',
  // './spec/javascripts/ide/components/error_message_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/error_message_spec.js',
  // './spec/javascripts/ide/components/external_link_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/external_link_spec.js',
  // './spec/javascripts/ide/components/file_finder/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/file_finder/index_spec.js',
  // './spec/javascripts/ide/components/file_finder/item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/file_finder/item_spec.js',
  // './spec/javascripts/ide/components/ide_review_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_review_spec.js',
  // './spec/javascripts/ide/components/ide_side_bar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_side_bar_spec.js',
  // './spec/javascripts/ide/components/ide_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_spec.js',
  // './spec/javascripts/ide/components/ide_status_bar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_status_bar_spec.js',
  // './spec/javascripts/ide/components/ide_tree_list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_tree_list_spec.js',
  // './spec/javascripts/ide/components/ide_tree_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/ide_tree_spec.js',
  // './spec/javascripts/ide/components/jobs/detail_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/detail_spec.js',
  // './spec/javascripts/ide/components/jobs/detail/description_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/detail/description_spec.js',
  // './spec/javascripts/ide/components/jobs/detail/scroll_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/detail/scroll_button_spec.js',
  // './spec/javascripts/ide/components/jobs/item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/item_spec.js',
  // './spec/javascripts/ide/components/jobs/list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/list_spec.js',
  // './spec/javascripts/ide/components/jobs/stage_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/jobs/stage_spec.js',
  // './spec/javascripts/ide/components/merge_requests/info_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/merge_requests/info_spec.js',
  // './spec/javascripts/ide/components/merge_requests/item_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/merge_requests/item_spec.js',
  // './spec/javascripts/ide/components/merge_requests/list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/merge_requests/list_spec.js',
  // './spec/javascripts/ide/components/nav_dropdown_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/nav_dropdown_button_spec.js',
  // './spec/javascripts/ide/components/nav_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/nav_dropdown_spec.js',
  // './spec/javascripts/ide/components/new_dropdown/button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/new_dropdown/button_spec.js',
  // './spec/javascripts/ide/components/new_dropdown/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/new_dropdown/index_spec.js',
  // './spec/javascripts/ide/components/new_dropdown/modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/new_dropdown/modal_spec.js',
  // './spec/javascripts/ide/components/new_dropdown/upload_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/new_dropdown/upload_spec.js',
  // './spec/javascripts/ide/components/panes/right_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/panes/right_spec.js',
  // './spec/javascripts/ide/components/pipelines/list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/pipelines/list_spec.js',
  // './spec/javascripts/ide/components/preview/clientside_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/preview/clientside_spec.js',
  // './spec/javascripts/ide/components/preview/navigator_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/preview/navigator_spec.js',
  // './spec/javascripts/ide/components/repo_commit_section_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_commit_section_spec.js',
  // './spec/javascripts/ide/components/repo_editor_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_editor_spec.js',
  // './spec/javascripts/ide/components/repo_file_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_file_spec.js',
  // './spec/javascripts/ide/components/repo_loading_file_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_loading_file_spec.js',
  // './spec/javascripts/ide/components/repo_tab_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_tab_spec.js',
  // './spec/javascripts/ide/components/repo_tabs_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/repo_tabs_spec.js',
  // './spec/javascripts/ide/components/shared/tokened_input_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/components/shared/tokened_input_spec.js',
  // './spec/javascripts/ide/ide_router_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/ide_router_spec.js',
  // './spec/javascripts/ide/lib/common/disposable_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/common/disposable_spec.js',
  // './spec/javascripts/ide/lib/common/model_manager_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/common/model_manager_spec.js',
  // './spec/javascripts/ide/lib/common/model_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/common/model_spec.js',
  // './spec/javascripts/ide/lib/decorations/controller_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/decorations/controller_spec.js',
  // './spec/javascripts/ide/lib/diff/controller_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/diff/controller_spec.js',
  // './spec/javascripts/ide/lib/diff/diff_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/diff/diff_spec.js',
  // './spec/javascripts/ide/lib/editor_options_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/editor_options_spec.js',
  // './spec/javascripts/ide/lib/editor_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/lib/editor_spec.js',
  // './spec/javascripts/ide/stores/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/actions_spec.js',
  // './spec/javascripts/ide/stores/actions/file_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/actions/file_spec.js',
  // './spec/javascripts/ide/stores/actions/merge_request_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/actions/merge_request_spec.js',
  // './spec/javascripts/ide/stores/actions/project_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/actions/project_spec.js',
  // './spec/javascripts/ide/stores/actions/tree_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/actions/tree_spec.js',
  // './spec/javascripts/ide/stores/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/getters_spec.js',
  // './spec/javascripts/ide/stores/modules/branches/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/branches/actions_spec.js',
  // './spec/javascripts/ide/stores/modules/branches/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/branches/mutations_spec.js',
  // './spec/javascripts/ide/stores/modules/commit/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/commit/actions_spec.js',
  // './spec/javascripts/ide/stores/modules/commit/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/commit/getters_spec.js',
  // './spec/javascripts/ide/stores/modules/commit/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/commit/mutations_spec.js',
  // './spec/javascripts/ide/stores/modules/merge_requests/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/merge_requests/actions_spec.js',
  // './spec/javascripts/ide/stores/modules/merge_requests/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/merge_requests/mutations_spec.js',
  // './spec/javascripts/ide/stores/modules/pipelines/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/pipelines/actions_spec.js',
  // './spec/javascripts/ide/stores/modules/pipelines/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/pipelines/getters_spec.js',
  // './spec/javascripts/ide/stores/modules/pipelines/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/modules/pipelines/mutations_spec.js',
  // './spec/javascripts/ide/stores/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/mutations_spec.js',
  // './spec/javascripts/ide/stores/mutations/branch_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/mutations/branch_spec.js',
  // './spec/javascripts/ide/stores/mutations/file_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/mutations/file_spec.js',
  // './spec/javascripts/ide/stores/mutations/merge_request_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/mutations/merge_request_spec.js',
  // './spec/javascripts/ide/stores/mutations/tree_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/mutations/tree_spec.js',
  // './spec/javascripts/ide/stores/utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/ide/stores/utils_spec.js',
  // './spec/javascripts/image_diff/helpers/badge_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/helpers/badge_helper_spec.js',
  // './spec/javascripts/image_diff/helpers/comment_indicator_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/helpers/comment_indicator_helper_spec.js',
  // './spec/javascripts/image_diff/helpers/dom_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/helpers/dom_helper_spec.js',
  // './spec/javascripts/image_diff/helpers/utils_helper_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/helpers/utils_helper_spec.js',
  // './spec/javascripts/image_diff/image_badge_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/image_badge_spec.js',
  // './spec/javascripts/image_diff/image_diff_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/image_diff_spec.js',
  // './spec/javascripts/image_diff/init_discussion_tab_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/init_discussion_tab_spec.js',
  // './spec/javascripts/image_diff/replaced_image_diff_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/replaced_image_diff_spec.js',
  // './spec/javascripts/image_diff/view_types_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/image_diff/view_types_spec.js',
  // './spec/javascripts/importer_status_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/importer_status_spec.js',
  // './spec/javascripts/integrations/integration_settings_form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/integrations/integration_settings_form_spec.js',
  // './spec/javascripts/issuable_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issuable_spec.js',
  // './spec/javascripts/issue_show/components/app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/app_spec.js',
  // './spec/javascripts/issue_show/components/description_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/description_spec.js',
  // './spec/javascripts/issue_show/components/edit_actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/edit_actions_spec.js',
  // './spec/javascripts/issue_show/components/edited_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/edited_spec.js',
  // './spec/javascripts/issue_show/components/fields/description_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/fields/description_spec.js',
  // './spec/javascripts/issue_show/components/fields/description_template_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/fields/description_template_spec.js',
  // './spec/javascripts/issue_show/components/fields/title_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/fields/title_spec.js',
  // './spec/javascripts/issue_show/components/form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/form_spec.js',
  // './spec/javascripts/issue_show/components/title_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_show/components/title_spec.js',
  // './spec/javascripts/issue_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/issue_spec.js',
  // './spec/javascripts/job_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/job_spec.js',
  // './spec/javascripts/jobs/artifacts_block_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/artifacts_block_spec.js',
  // './spec/javascripts/jobs/commit_block_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/commit_block_spec.js',
  // './spec/javascripts/jobs/components/job_log_controllers_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/components/job_log_controllers_spec.js',
  // './spec/javascripts/jobs/empty_state_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/empty_state_spec.js',
  // './spec/javascripts/jobs/erased_block_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/erased_block_spec.js',
  // './spec/javascripts/jobs/header_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/header_spec.js',
  // './spec/javascripts/jobs/job_details_mediator_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/job_details_mediator_spec.js',
  // './spec/javascripts/jobs/job_log_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/job_log_spec.js',
  // './spec/javascripts/jobs/job_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/job_store_spec.js',
  // './spec/javascripts/jobs/jobs_container_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/jobs_container_spec.js',
  // './spec/javascripts/jobs/sidebar_detail_row_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/sidebar_detail_row_spec.js',
  // './spec/javascripts/jobs/sidebar_details_block_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/sidebar_details_block_spec.js',
  // './spec/javascripts/jobs/stages_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/stages_dropdown_spec.js',
  // './spec/javascripts/jobs/stuck_block_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/stuck_block_spec.js',
  // './spec/javascripts/jobs/trigger_value_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/jobs/trigger_value_spec.js',
  // './spec/javascripts/labels_issue_sidebar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/labels_issue_sidebar_spec.js',
  // './spec/javascripts/labels_select_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/labels_select_spec.js',
  // './spec/javascripts/landing_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/landing_spec.js',
  // './spec/javascripts/lazy_loader_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lazy_loader_spec.js',
  // './spec/javascripts/lib/utils/accessor_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/accessor_spec.js',
  // './spec/javascripts/lib/utils/ajax_cache_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/ajax_cache_spec.js',
  // './spec/javascripts/lib/utils/cache_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/cache_spec.js',
  // './spec/javascripts/lib/utils/common_utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/common_utils_spec.js',
  // './spec/javascripts/lib/utils/csrf_token_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/csrf_token_spec.js',
  // './spec/javascripts/lib/utils/datefix_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/datefix_spec.js',
  // './spec/javascripts/lib/utils/dom_utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/dom_utils_spec.js',
  // './spec/javascripts/lib/utils/image_utility_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/image_utility_spec.js',
  // './spec/javascripts/lib/utils/number_utility_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/number_utility_spec.js',
  // './spec/javascripts/lib/utils/poll_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/poll_spec.js',
  // './spec/javascripts/lib/utils/sticky_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/sticky_spec.js',
  // './spec/javascripts/lib/utils/text_markdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/text_markdown_spec.js',
  // './spec/javascripts/lib/utils/text_utility_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/text_utility_spec.js',
  // './spec/javascripts/lib/utils/tick_formats_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/tick_formats_spec.js',
  // './spec/javascripts/lib/utils/url_utility_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/url_utility_spec.js',
  // './spec/javascripts/lib/utils/users_cache_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/lib/utils/users_cache_spec.js',
  // './spec/javascripts/line_highlighter_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/line_highlighter_spec.js',
  // './spec/javascripts/locale/ensure_single_line_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/locale/ensure_single_line_spec.js',
  // './spec/javascripts/locale/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/locale/index_spec.js',
  // './spec/javascripts/locale/sprintf_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/locale/sprintf_spec.js',
  // './spec/javascripts/merge_request_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/merge_request_spec.js',
  // './spec/javascripts/merge_request_tabs_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/merge_request_tabs_spec.js',
  // './spec/javascripts/mini_pipeline_graph_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/mini_pipeline_graph_dropdown_spec.js',
  // './spec/javascripts/monitoring/dashboard_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/dashboard_spec.js',
  // './spec/javascripts/monitoring/dashboard_state_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/dashboard_state_spec.js',
  // './spec/javascripts/monitoring/graph_path_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph_path_spec.js',
  // './spec/javascripts/monitoring/graph_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph_spec.js',
  // './spec/javascripts/monitoring/graph/axis_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/axis_spec.js',
  // './spec/javascripts/monitoring/graph/deployment_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/deployment_spec.js',
  // './spec/javascripts/monitoring/graph/flag_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/flag_spec.js',
  // './spec/javascripts/monitoring/graph/legend_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/legend_spec.js',
  // './spec/javascripts/monitoring/graph/track_info_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/track_info_spec.js',
  // './spec/javascripts/monitoring/graph/track_line_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/graph/track_line_spec.js',
  // './spec/javascripts/monitoring/monitoring_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/monitoring_store_spec.js',
  // './spec/javascripts/monitoring/utils/multiple_time_series_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/monitoring/utils/multiple_time_series_spec.js',
  // './spec/javascripts/my_test_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/my_test_spec.js',
  // './spec/javascripts/namespace_select_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/namespace_select_spec.js',
  // './spec/javascripts/new_branch_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/new_branch_spec.js',
  // './spec/javascripts/notebook/cells/code_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/cells/code_spec.js',
  // './spec/javascripts/notebook/cells/markdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/cells/markdown_spec.js',
  // './spec/javascripts/notebook/cells/output/html_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/cells/output/html_spec.js',
  // './spec/javascripts/notebook/cells/output/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/cells/output/index_spec.js',
  // './spec/javascripts/notebook/cells/prompt_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/cells/prompt_spec.js',
  // './spec/javascripts/notebook/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/index_spec.js',
  // './spec/javascripts/notebook/lib/highlight_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notebook/lib/highlight_spec.js',
  // './spec/javascripts/notes_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes_spec.js',
  // './spec/javascripts/notes/components/comment_form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/comment_form_spec.js',
  // './spec/javascripts/notes/components/diff_with_note_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/diff_with_note_spec.js',
  // './spec/javascripts/notes/components/discussion_counter_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/discussion_counter_spec.js',
  // './spec/javascripts/notes/components/note_actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_actions_spec.js',
  // './spec/javascripts/notes/components/note_app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_app_spec.js',
  // './spec/javascripts/notes/components/note_attachment_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_attachment_spec.js',
  // './spec/javascripts/notes/components/note_awards_list_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_awards_list_spec.js',
  // './spec/javascripts/notes/components/note_body_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_body_spec.js',
  // './spec/javascripts/notes/components/note_edited_text_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_edited_text_spec.js',
  // './spec/javascripts/notes/components/note_form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_form_spec.js',
  // './spec/javascripts/notes/components/note_header_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_header_spec.js',
  // './spec/javascripts/notes/components/note_signed_out_widget_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/note_signed_out_widget_spec.js',
  // './spec/javascripts/notes/components/noteable_discussion_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/noteable_discussion_spec.js',
  // './spec/javascripts/notes/components/noteable_note_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/components/noteable_note_spec.js',
  // './spec/javascripts/notes/stores/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/stores/actions_spec.js',
  // './spec/javascripts/notes/stores/collapse_utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/stores/collapse_utils_spec.js',
  // './spec/javascripts/notes/stores/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/stores/getters_spec.js',
  // './spec/javascripts/notes/stores/mutation_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/notes/stores/mutation_spec.js',
  // './spec/javascripts/oauth_remember_me_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/oauth_remember_me_spec.js',
  // './spec/javascripts/pager_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pager_spec.js',
  // './spec/javascripts/pages/admin/abuse_reports/abuse_reports_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/admin/abuse_reports/abuse_reports_spec.js',
  // './spec/javascripts/pages/admin/jobs/index/components/stop_jobs_modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/admin/jobs/index/components/stop_jobs_modal_spec.js',
  // './spec/javascripts/pages/labels/components/promote_label_modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/labels/components/promote_label_modal_spec.js',
  // './spec/javascripts/pages/milestones/shared/components/delete_milestone_modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/milestones/shared/components/delete_milestone_modal_spec.js',
  // './spec/javascripts/pages/milestones/shared/components/promote_milestone_modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/milestones/shared/components/promote_milestone_modal_spec.js',
  // './spec/javascripts/pages/profiles/show/emoji_menu_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/profiles/show/emoji_menu_spec.js',
  // './spec/javascripts/pages/projects/pipeline_schedules/shared/components/interval_pattern_input_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/projects/pipeline_schedules/shared/components/interval_pattern_input_spec.js',
  // './spec/javascripts/pages/projects/pipeline_schedules/shared/components/pipeline_schedule_callout_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pages/projects/pipeline_schedules/shared/components/pipeline_schedule_callout_spec.js',
  // './spec/javascripts/pdf/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pdf/index_spec.js',
  // './spec/javascripts/pdf/page_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pdf/page_spec.js',
  // './spec/javascripts/performance_bar/components/detailed_metric_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/performance_bar/components/detailed_metric_spec.js',
  // './spec/javascripts/performance_bar/components/performance_bar_app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/performance_bar/components/performance_bar_app_spec.js',
  // './spec/javascripts/performance_bar/components/request_selector_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/performance_bar/components/request_selector_spec.js',
  // './spec/javascripts/performance_bar/components/simple_metric_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/performance_bar/components/simple_metric_spec.js',
  // './spec/javascripts/performance_bar/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/performance_bar/index_spec.js',
  // './spec/javascripts/pipelines_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines_spec.js',
  // './spec/javascripts/pipelines/blank_state_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/blank_state_spec.js',
  // './spec/javascripts/pipelines/empty_state_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/empty_state_spec.js',
  // './spec/javascripts/pipelines/graph/action_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/action_component_spec.js',
  // './spec/javascripts/pipelines/graph/dropdown_job_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/dropdown_job_component_spec.js',
  // './spec/javascripts/pipelines/graph/graph_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/graph_component_spec.js',
  // './spec/javascripts/pipelines/graph/job_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/job_component_spec.js',
  // './spec/javascripts/pipelines/graph/job_name_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/job_name_component_spec.js',
  // './spec/javascripts/pipelines/graph/stage_column_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/graph/stage_column_component_spec.js',
  // './spec/javascripts/pipelines/header_component_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/header_component_spec.js',
  // './spec/javascripts/pipelines/nav_controls_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/nav_controls_spec.js',
  // './spec/javascripts/pipelines/pipeline_details_mediator_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipeline_details_mediator_spec.js',
  // './spec/javascripts/pipelines/pipeline_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipeline_store_spec.js',
  // './spec/javascripts/pipelines/pipeline_url_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipeline_url_spec.js',
  // './spec/javascripts/pipelines/pipelines_actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_actions_spec.js',
  // './spec/javascripts/pipelines/pipelines_artifacts_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_artifacts_spec.js',
  // './spec/javascripts/pipelines/pipelines_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_spec.js',
  // './spec/javascripts/pipelines/pipelines_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_store_spec.js',
  // './spec/javascripts/pipelines/pipelines_table_row_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_table_row_spec.js',
  // './spec/javascripts/pipelines/pipelines_table_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/pipelines_table_spec.js',
  // './spec/javascripts/pipelines/stage_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/stage_spec.js',
  // './spec/javascripts/pipelines/time_ago_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pipelines/time_ago_spec.js',
  // './spec/javascripts/polyfills/element_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/polyfills/element_spec.js',
  // './spec/javascripts/pretty_time_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/pretty_time_spec.js',
  // './spec/javascripts/profile/account/components/delete_account_modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/profile/account/components/delete_account_modal_spec.js',
  // './spec/javascripts/profile/account/components/update_username_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/profile/account/components/update_username_spec.js',
  // './spec/javascripts/profile/add_ssh_key_validation_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/profile/add_ssh_key_validation_spec.js',
  // './spec/javascripts/project_select_combo_button_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/project_select_combo_button_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/components/gke_machine_type_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/components/gke_machine_type_dropdown_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/components/gke_project_id_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/components/gke_project_id_dropdown_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/components/gke_zone_dropdown_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/components/gke_zone_dropdown_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/stores/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/stores/actions_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/stores/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/stores/getters_spec.js',
  // './spec/javascripts/projects/gke_cluster_dropdowns/stores/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/gke_cluster_dropdowns/stores/mutations_spec.js',
  // './spec/javascripts/projects/project_import_gitlab_project_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/project_import_gitlab_project_spec.js',
  // './spec/javascripts/projects/project_new_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/projects/project_new_spec.js',
  // './spec/javascripts/prometheus_metrics/prometheus_metrics_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/prometheus_metrics/prometheus_metrics_spec.js',
  // './spec/javascripts/raven/index_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/raven/index_spec.js',
  // './spec/javascripts/raven/raven_config_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/raven/raven_config_spec.js',
  // './spec/javascripts/registry/components/app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/components/app_spec.js',
  // './spec/javascripts/registry/components/collapsible_container_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/components/collapsible_container_spec.js',
  // './spec/javascripts/registry/components/table_registry_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/components/table_registry_spec.js',
  // './spec/javascripts/registry/getters_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/getters_spec.js',
  // './spec/javascripts/registry/stores/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/stores/actions_spec.js',
  // './spec/javascripts/registry/stores/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/registry/stores/mutations_spec.js',
  // './spec/javascripts/reports/components/grouped_test_reports_app_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/grouped_test_reports_app_spec.js',
  // './spec/javascripts/reports/components/modal_open_name_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/modal_open_name_spec.js',
  // './spec/javascripts/reports/components/modal_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/modal_spec.js',
  // './spec/javascripts/reports/components/report_link_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/report_link_spec.js',
  // './spec/javascripts/reports/components/report_section_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/report_section_spec.js',
  // './spec/javascripts/reports/components/summary_row_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/summary_row_spec.js',
  // './spec/javascripts/reports/components/test_issue_body_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/components/test_issue_body_spec.js',
  // './spec/javascripts/reports/store/actions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/store/actions_spec.js',
  // './spec/javascripts/reports/store/mutations_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/store/mutations_spec.js',
  // './spec/javascripts/reports/store/utils_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/reports/store/utils_spec.js',
  // './spec/javascripts/right_sidebar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/right_sidebar_spec.js',
  // './spec/javascripts/search_autocomplete_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/search_autocomplete_spec.js',
  // './spec/javascripts/search_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/search_spec.js',
  // './spec/javascripts/settings_panels_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/settings_panels_spec.js',
  // './spec/javascripts/shared/popover_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/shared/popover_spec.js',
  // './spec/javascripts/shortcuts_dashboard_navigation_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/shortcuts_dashboard_navigation_spec.js',
  // './spec/javascripts/shortcuts_issuable_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/shortcuts_issuable_spec.js',
  // './spec/javascripts/shortcuts_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/shortcuts_spec.js',
  // './spec/javascripts/sidebar/assignee_title_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/assignee_title_spec.js',
  // './spec/javascripts/sidebar/assignees_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/assignees_spec.js',
  // './spec/javascripts/sidebar/components/time_tracking/time_tracker_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/components/time_tracking/time_tracker_spec.js',
  // './spec/javascripts/sidebar/confidential_edit_buttons_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/confidential_edit_buttons_spec.js',
  // './spec/javascripts/sidebar/confidential_edit_form_buttons_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/confidential_edit_form_buttons_spec.js',
  // './spec/javascripts/sidebar/confidential_issue_sidebar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/confidential_issue_sidebar_spec.js',
  // './spec/javascripts/sidebar/lock/edit_form_buttons_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/lock/edit_form_buttons_spec.js',
  // './spec/javascripts/sidebar/lock/edit_form_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/lock/edit_form_spec.js',
  // './spec/javascripts/sidebar/lock/lock_issue_sidebar_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/lock/lock_issue_sidebar_spec.js',
  // './spec/javascripts/sidebar/participants_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/participants_spec.js',
  // './spec/javascripts/sidebar/sidebar_assignees_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/sidebar_assignees_spec.js',
  // './spec/javascripts/sidebar/sidebar_mediator_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/sidebar_mediator_spec.js',
  // './spec/javascripts/sidebar/sidebar_move_issue_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/sidebar_move_issue_spec.js',
  // './spec/javascripts/sidebar/sidebar_store_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/sidebar_store_spec.js',
  // './spec/javascripts/sidebar/sidebar_subscriptions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/sidebar_subscriptions_spec.js',
  // './spec/javascripts/sidebar/subscriptions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/subscriptions_spec.js',
  // './spec/javascripts/sidebar/todo_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/sidebar/todo_spec.js',
  // './spec/javascripts/signin_tabs_memoizer_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/signin_tabs_memoizer_spec.js',
  // './spec/javascripts/smart_interval_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/smart_interval_spec.js',
  // './spec/javascripts/syntax_highlight_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/syntax_highlight_spec.js',
  // './spec/javascripts/todos_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/todos_spec.js',
  // './spec/javascripts/toggle_buttons_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/toggle_buttons_spec.js',
  // './spec/javascripts/u2f/authenticate_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/u2f/authenticate_spec.js',
  // './spec/javascripts/u2f/register_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/u2f/register_spec.js',
  // './spec/javascripts/u2f/util_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/u2f/util_spec.js',
  // './spec/javascripts/version_check_image_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/version_check_image_spec.js',
  // './spec/javascripts/vue_mr_widget/components/deployment_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/deployment_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_author_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_author_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_author_time_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_author_time_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_header_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_header_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_memory_usage_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_memory_usage_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_merge_help_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_merge_help_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_pipeline_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_pipeline_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_rebase_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_rebase_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_related_links_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_related_links_spec.js',
  // './spec/javascripts/vue_mr_widget/components/mr_widget_status_icon_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/mr_widget_status_icon_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_archived_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_archived_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_auto_merge_failed_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_auto_merge_failed_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_checking_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_checking_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_closed_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_closed_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_conflicts_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_conflicts_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_failed_to_merge_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_failed_to_merge_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_merge_when_pipeline_succeeds_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_merge_when_pipeline_succeeds_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_merged_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_merged_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_merging_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_merging_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_missing_branch_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_missing_branch_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_not_allowed_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_not_allowed_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_nothing_to_merge_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_nothing_to_merge_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_pipeline_blocked_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_pipeline_blocked_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_pipeline_failed_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_pipeline_failed_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_ready_to_merge_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_ready_to_merge_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_sha_mismatch_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_sha_mismatch_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_unresolved_discussions_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_unresolved_discussions_spec.js',
  // './spec/javascripts/vue_mr_widget/components/states/mr_widget_wip_spec.js':
  //   '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/components/states/mr_widget_wip_spec.js',
  './spec/javascripts/vue_mr_widget/mr_widget_options_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/mr_widget_options_spec.js',
  './spec/javascripts/vue_mr_widget/stores/get_state_key_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/stores/get_state_key_spec.js',
  './spec/javascripts/vue_mr_widget/stores/mr_widget_store_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_mr_widget/stores/mr_widget_store_spec.js',
  './spec/javascripts/vue_shared/components/bar_chart_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/bar_chart_spec.js',
  './spec/javascripts/vue_shared/components/callout_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/callout_spec.js',
  './spec/javascripts/vue_shared/components/ci_badge_link_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/ci_badge_link_spec.js',
  './spec/javascripts/vue_shared/components/ci_icon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/ci_icon_spec.js',
  './spec/javascripts/vue_shared/components/clipboard_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/clipboard_button_spec.js',
  './spec/javascripts/vue_shared/components/code_block_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/code_block_spec.js',
  './spec/javascripts/vue_shared/components/commit_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/commit_spec.js',
  './spec/javascripts/vue_shared/components/content_viewer/content_viewer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/content_viewer/content_viewer_spec.js',
  './spec/javascripts/vue_shared/components/deprecated_modal_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/deprecated_modal_spec.js',
  './spec/javascripts/vue_shared/components/diff_viewer/diff_viewer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/diff_viewer/diff_viewer_spec.js',
  './spec/javascripts/vue_shared/components/diff_viewer/viewers/image_diff_viewer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/diff_viewer/viewers/image_diff_viewer_spec.js',
  './spec/javascripts/vue_shared/components/dropdown/dropdown_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/dropdown/dropdown_button_spec.js',
  './spec/javascripts/vue_shared/components/dropdown/dropdown_hidden_input_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/dropdown/dropdown_hidden_input_spec.js',
  './spec/javascripts/vue_shared/components/dropdown/dropdown_search_input_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/dropdown/dropdown_search_input_spec.js',
  './spec/javascripts/vue_shared/components/expand_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/expand_button_spec.js',
  './spec/javascripts/vue_shared/components/file_icon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/file_icon_spec.js',
  './spec/javascripts/vue_shared/components/gl_modal_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/gl_modal_spec.js',
  './spec/javascripts/vue_shared/components/header_ci_component_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/header_ci_component_spec.js',
  './spec/javascripts/vue_shared/components/icon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/icon_spec.js',
  './spec/javascripts/vue_shared/components/identicon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/identicon_spec.js',
  './spec/javascripts/vue_shared/components/issue/issue_warning_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/issue/issue_warning_spec.js',
  './spec/javascripts/vue_shared/components/lib/utils/dom_utils_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/lib/utils/dom_utils_spec.js',
  './spec/javascripts/vue_shared/components/loading_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/loading_button_spec.js',
  './spec/javascripts/vue_shared/components/loading_icon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/loading_icon_spec.js',
  './spec/javascripts/vue_shared/components/markdown/field_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/markdown/field_spec.js',
  './spec/javascripts/vue_shared/components/markdown/header_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/markdown/header_spec.js',
  './spec/javascripts/vue_shared/components/markdown/toolbar_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/markdown/toolbar_spec.js',
  './spec/javascripts/vue_shared/components/memory_graph_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/memory_graph_spec.js',
  './spec/javascripts/vue_shared/components/navigation_tabs_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/navigation_tabs_spec.js',
  './spec/javascripts/vue_shared/components/notes/placeholder_note_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/notes/placeholder_note_spec.js',
  './spec/javascripts/vue_shared/components/notes/placeholder_system_note_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/notes/placeholder_system_note_spec.js',
  './spec/javascripts/vue_shared/components/notes/system_note_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/notes/system_note_spec.js',
  './spec/javascripts/vue_shared/components/panel_resizer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/panel_resizer_spec.js',
  './spec/javascripts/vue_shared/components/pikaday_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/pikaday_spec.js',
  './spec/javascripts/vue_shared/components/project_avatar/default_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/project_avatar/default_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/collapsed_calendar_icon_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/collapsed_calendar_icon_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/collapsed_grouped_date_picker_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/collapsed_grouped_date_picker_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/date_picker_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/date_picker_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/base_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/base_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_button_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_create_label_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_create_label_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_footer_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_footer_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_header_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_header_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_search_input_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_search_input_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_title_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_title_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_value_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/labels_select/dropdown_value_spec.js',
  './spec/javascripts/vue_shared/components/sidebar/toggle_sidebar_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/sidebar/toggle_sidebar_spec.js',
  './spec/javascripts/vue_shared/components/skeleton_loading_container_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/skeleton_loading_container_spec.js',
  './spec/javascripts/vue_shared/components/stacked_progress_bar_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/stacked_progress_bar_spec.js',
  './spec/javascripts/vue_shared/components/table_pagination_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/table_pagination_spec.js',
  './spec/javascripts/vue_shared/components/tabs/tab_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/tabs/tab_spec.js',
  './spec/javascripts/vue_shared/components/tabs/tabs_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/tabs/tabs_spec.js',
  './spec/javascripts/vue_shared/components/time_ago_tooltip_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/time_ago_tooltip_spec.js',
  './spec/javascripts/vue_shared/components/toggle_button_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/toggle_button_spec.js',
  './spec/javascripts/vue_shared/components/user_avatar/user_avatar_image_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/user_avatar/user_avatar_image_spec.js',
  './spec/javascripts/vue_shared/components/user_avatar/user_avatar_link_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/user_avatar/user_avatar_link_spec.js',
  './spec/javascripts/vue_shared/components/user_avatar/user_avatar_svg_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/components/user_avatar/user_avatar_svg_spec.js',
  './spec/javascripts/vue_shared/directives/tooltip_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/directives/tooltip_spec.js',
  './spec/javascripts/vue_shared/translate_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/vue_shared/translate_spec.js',
  './spec/javascripts/zen_mode_spec.js':
    '/Users/mike/Projects/gitlab-ce/gitlab/spec/javascripts/zen_mode_spec.js',
};
// createContext(ROOT_PATH, specFilters || `**/${TEST_CONTEXT_PATH}/**/*spec.js`);
const codeContext = {}; //createContext(ROOT_PATH, `**/${CODE_CONTEXT_PATH}/**/*.js`);
const testList = Object.keys(testContext);

if (!testList.length) {
  fatalError('Your filter did not match any test files.');
}

if (!testList.every(file => file.includes(TEST_CONTEXT_PATH))) {
  fatalError('Test files must be located within spec/javascripts.');
}

console.log(`Found ${testList.length} test files`);
console.log(testContext);

// Override webpack require contexts within test_bundle
webpackConfig.resolve.alias['KARMA_TEST_CONTEXT$'] = path.join(ROOT_PATH, TEST_CONTEXT_PATH);
webpackConfig.resolve.alias['KARMA_CODE_CONTEXT$'] = path.join(ROOT_PATH, CODE_CONTEXT_PATH);
const KARMA_TEST_CONTEXT_REGEX = new RegExp(`${escapeRegex(TEST_CONTEXT_PATH)}$`);
const KARMA_CODE_CONTEXT_REGEX = new RegExp(`${escapeRegex(CODE_CONTEXT_PATH)}$`);
webpackConfig.plugins.push(
  new webpack.ContextReplacementPlugin(KARMA_TEST_CONTEXT_REGEX, ROOT_PATH, testContext),
  new webpack.ContextReplacementPlugin(KARMA_CODE_CONTEXT_REGEX, ROOT_PATH, codeContext)
);

// Karma configuration
module.exports = function(config) {
  process.env.TZ = 'Etc/UTC';

  const progressReporter = process.env.CI ? 'mocha' : 'progress';

  const karmaConfig = {
    basePath: ROOT_PATH,
    browsers: ['ChromeHeadlessCustom'],
    customLaunchers: {
      ChromeHeadlessCustom: {
        base: 'ChromeHeadless',
        displayName: 'Chrome',
        flags: [
          // chrome cannot run in sandboxed mode inside a docker container unless it is run with
          // escalated kernel privileges (e.g. docker run --cap-add=CAP_SYS_ADMIN)
          '--no-sandbox',
        ],
      },
    },
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: 'spec/javascripts/fixtures/**/*@(.json|.html|.html.raw|.png)', included: false },
    ],
    preprocessors: {
      'spec/javascripts/**/*.js': ['webpack', 'sourcemap'],
    },
    reporters: [progressReporter],
    webpack: webpackConfig,
    webpackMiddleware: { stats: 'errors-only' },
  };

  if (process.env.BABEL_ENV === 'coverage' || process.env.NODE_ENV === 'coverage') {
    karmaConfig.reporters.push('coverage-istanbul');
    karmaConfig.coverageIstanbulReporter = {
      reports: ['html', 'text-summary'],
      dir: 'coverage-javascript/',
      subdir: '.',
      fixWebpackSourcePaths: true,
    };
    karmaConfig.browserNoActivityTimeout = 60000; // 60 seconds
  }

  if (process.env.DEBUG) {
    karmaConfig.logLevel = config.LOG_DEBUG;
    process.env.CHROME_LOG_FILE = process.env.CHROME_LOG_FILE || 'chrome_debug.log';
  }

  if (process.env.CHROME_LOG_FILE) {
    karmaConfig.customLaunchers.ChromeHeadlessCustom.flags.push('--enable-logging', '--v=1');
  }

  config.set(karmaConfig);
};
