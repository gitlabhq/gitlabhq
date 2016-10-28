/* eslint-disable */

/**
 * Simulate sprockets compile order of application.js through CommonJS require statements
 *
 * Currently exports everything appropriate to window until the scripts that rely on this behavior
 * can be refactored.
 *
 * Test the output from this against sprockets output and it should be almost identical apart from
 * webpack's CommonJS wrapper. You can add the following line to webpack.config.js to fix the
 * script indentation:
 * config.output.sourcePrefix = '';
 */

/*= require jquery2 */
window.jQuery = window.$ = require('jquery');

/*= require jquery-ui/autocomplete */
// depends on jquery-ui/core, jquery-ui/widget, jquery-ui/menu, jquery-ui/position
require('jquery-ui/ui/core');
require('jquery-ui/ui/widget');
require('jquery-ui/ui/position');
require('jquery-ui/ui/menu');
require('jquery-ui/ui/autocomplete');

/*= require jquery-ui/datepicker */
// depends on jquery-ui/core
require('jquery-ui/ui/datepicker');

/*= require jquery-ui/draggable */
// depends on jquery-ui/core, jquery-ui/widget, jquery-ui/mouse
require('jquery-ui/ui/mouse');
require('jquery-ui/ui/draggable');

/*= require jquery-ui/effect-highlight */
// depends on jquery-ui/effect
require('jquery-ui/ui/effect');
require('jquery-ui/ui/effect-highlight');

/*= require jquery-ui/sortable */
// depends on jquery-ui/core, jquery-ui/widget, jquery-ui/mouse
require('jquery-ui/ui/sortable');

/*= require jquery_ujs */
require('jquery-ujs');

/*= require jquery.endless-scroll */
require('vendor/jquery.endless-scroll');

/*= require jquery.highlight */
require('vendor/jquery.highlight');

/*= require jquery.waitforimages */
require('vendor/jquery.waitforimages');

/*= require jquery.atwho */
require('vendor/jquery.caret'); // required by jquery.atwho
require('vendor/jquery.atwho');

/*= require jquery.scrollTo */
require('vendor/jquery.scrollTo');

/*= require jquery.turbolinks */
require('vendor/jquery.turbolinks');

/*= require js.cookie */
window.Cookies = require('vendor/js.cookie');

/*= require turbolinks */
require('vendor/turbolinks');

/*= require autosave */
require('../autosave');

/*= require bootstrap/affix */
require('bootstrap/js/affix');

/*= require bootstrap/alert */
require('bootstrap/js/alert');

/*= require bootstrap/button */
require('bootstrap/js/button');

/*= require bootstrap/collapse */
require('bootstrap/js/collapse');

/*= require bootstrap/dropdown */
require('bootstrap/js/dropdown');

/*= require bootstrap/modal */
require('bootstrap/js/modal');

/*= require bootstrap/scrollspy */
require('bootstrap/js/scrollspy');

/*= require bootstrap/tab */
require('bootstrap/js/tab');

/*= require bootstrap/transition */
require('bootstrap/js/transition');

/*= require bootstrap/tooltip */
require('bootstrap/js/tooltip');

/*= require bootstrap/popover */
require('bootstrap/js/popover');

/*= require select2 */
require('select2/select2.js');

/*= require underscore */
window._ = require('underscore');

/*= require dropzone */
window.Dropzone = require('dropzone');

/*= require mousetrap */
require('mousetrap');

/*= require mousetrap/pause */
require('mousetrap/plugins/pause/mousetrap-pause');

/*= require shortcuts */
require('../shortcuts');

/*= require shortcuts_navigation */
require('../shortcuts_navigation');

/*= require shortcuts_dashboard_navigation */
require('../shortcuts_dashboard_navigation');

/*= require shortcuts_issuable */
require('../shortcuts_issuable');

/*= require shortcuts_network */
require('../shortcuts_network');

/*= require jquery.nicescroll */
require('vendor/jquery.nicescroll');

/*= require date.format */
require('vendor/date.format');

/*= require_directory ./behaviors */
require('vendor/jquery.ba-resize');
window.autosize = require('vendor/autosize');
require('../behaviors/autosize'); // requires vendor/jquery.ba-resize and vendor/autosize
require('../behaviors/details_behavior');
require('../extensions/jquery');
require('../behaviors/quick_submit'); // requires extensions/jquery
require('../behaviors/requires_input');
require('../behaviors/toggler_behavior');

/*= require_directory ./blob */
require('../blob/template_selector');
require('../blob/blob_ci_yaml'); // requires template_selector
require('../blob/blob_file_dropzone');
require('../blob/blob_gitignore_selector');
require('../blob/blob_gitignore_selectors');
require('../blob/blob_license_selector');
require('../blob/blob_license_selectors');

/*= require_directory ./templates */
require('../templates/issuable_template_selector');
require('../templates/issuable_template_selectors');

/*= require_directory ./commit */
require('../commit/file');
require('../commit/image_file');

/*= require_directory ./extensions */
require('../extensions/array');
require('../extensions/element');

/*= require_directory ./lib/utils */
require('../lib/utils/animate');
require('../lib/utils/common_utils');
require('../lib/utils/datetime_utility');
// require('../lib/utils/emoji_aliases.js.erb');
window.gl.emojiAliases = function() { return require('emoji-aliases'); };
require('../lib/utils/jquery.timeago');
require('../lib/utils/notify');
require('../lib/utils/text_utility');
require('../lib/utils/type_utility');
require('../lib/utils/url_utility');

/*= require_directory ./u2f */
require('../u2f/authenticate');
require('../u2f/error');
require('../u2f/register');
require('../u2f/util');

/*= require_directory . */
require('../abuse_reports');
require('../activities');
require('../admin');
require('../api');
require('../aside');
require('../awards_handler');
require('../breakpoints');
require('../broadcast_message');
require('../build');
require('../build_artifacts');
require('../build_variables');
require('../commit');
require('../commits');
require('../compare');
require('../compare_autocomplete');
require('../confirm_danger_modal');
window.Clipboard = require('vendor/clipboard'); // required by copy_to_clipboard
require('../copy_to_clipboard');
require('../create_label');
require('vue'); // required by cycle_analytics
require('../cycle_analytics');
require('../diff');
require('../dispatcher');
require('../preview_markdown');
require('../dropzone_input');
require('../due_date_select');
require('../files_comment_button');
require('../flash');
require('../gfm_auto_complete');
require('../gl_dropdown');
require('../gl_field_errors');
require('../gl_form');
require('../group_avatar');
require('../groups_select');
require('../header');
require('../importer_status');
require('../issuable');
require('../issuable_context');
require('../issuable_form');
require('vendor/task_list'); // required by issue
require('../issue');
require('../issue_status_select');
require('../issues_bulk_assignment');
require('../label_manager');
require('../labels');
require('../labels_select');
require('../layout_nav');
require('../line_highlighter');
require('../logo');
require('../member_expiration_date');
require('../members');
require('../merge_request_tabs');
require('../merge_request');
require('../merge_request_widget');
require('../merged_buttons');
require('../milestone');
require('../milestone_select');
require('../namespace_select');
require('../new_branch_form');
require('../new_commit_form');
require('../notes');
require('../notifications_dropdown');
require('../notifications_form');
require('../pager');
require('../pipelines');
require('../project');
require('../project_avatar');
require('../project_find_file');
require('../project_fork');
require('../project_import');
require('../project_new');
require('../project_select');
require('../project_show');
require('../projects_list');
require('../right_sidebar');
require('../search');
require('../search_autocomplete');
require('../shortcuts_blob');
require('../shortcuts_find_file');
require('../sidebar');
require('../single_file_diff');
require('../snippets_list');
require('../star');
require('../subscription');
require('../subscription_select');
require('../syntax_highlight');
require('../todos');
require('../tree');
require('../user');
require('../user_tabs');
require('../username_validator');
require('../users_select');
require('vendor/latinise'); // required by wikis
require('../wikis');
require('../zen_mode');

/*= require fuzzaldrin-plus */
require('vendor/fuzzaldrin-plus');

require('../application');
