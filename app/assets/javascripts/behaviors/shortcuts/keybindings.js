import { memoize } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { __, s__ } from '~/locale';

/**
 * @param {object} command
 * @param {boolean} [command.customizable]
 */
const isCustomizable = ({ customizable }) => Boolean(customizable ?? true);

export const LOCAL_STORAGE_KEY = 'gl-keyboard-shortcuts-customizations';

/**
 * @returns { Object.<string, string[]> } A map of command ID => keys of all
 * keyboard shortcuts that have been customized by the user. These
 * customizations are fetched from `localStorage`. This function is memoized,
 * so its return value will not reflect changes made to the `localStorage` data
 * after it has been called once.
 *
 * @example
 * { "globalShortcuts.togglePerformanceBar": ["p e r f"] }
 */
export const getCustomizations = memoize(() => {
  let parsedCustomizations = {};
  const localStorageIsSafe = AccessorUtilities.canUseLocalStorage();

  if (localStorageIsSafe) {
    try {
      parsedCustomizations = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY) || '{}');
    } catch (e) {
      /* do nothing */
    }
  }

  return parsedCustomizations;
});

// All available commands
export const TOGGLE_KEYBOARD_SHORTCUTS_DIALOG = {
  id: 'globalShortcuts.toggleKeyboardShortcutsDialog',
  description: __('Toggle keyboard shortcuts help dialog'),
  defaultKeys: ['?'],
};

export const GO_TO_YOUR_PROJECTS = {
  id: 'globalShortcuts.goToYourProjects',
  description: __('Go to your projects'),
  defaultKeys: ['shift+p'],
};

export const GO_TO_YOUR_GROUPS = {
  id: 'globalShortcuts.goToYourGroups',
  description: __('Go to your groups'),
  defaultKeys: ['shift+g'],
};

export const GO_TO_ACTIVITY_FEED = {
  id: 'globalShortcuts.goToActivityFeed',
  description: __('Go to the activity feed'),
  defaultKeys: ['shift+a'],
};

export const GO_TO_MILESTONE_LIST = {
  id: 'globalShortcuts.goToMilestoneList',
  description: __('Go to the milestone list'),
  defaultKeys: ['shift+l'],
};

export const GO_TO_YOUR_SNIPPETS = {
  id: 'globalShortcuts.goToYourSnippets',
  description: __('Go to your snippets'),
  defaultKeys: ['shift+s'],
};

export const START_SEARCH = {
  id: 'globalShortcuts.startSearch',
  description: __('Start search'),
  defaultKeys: ['s', '/'],
};

export const FOCUS_FILTER_BAR = {
  id: 'globalShortcuts.focusFilterBar',
  description: __('Focus filter bar'),
  defaultKeys: ['f'],
};

export const GO_TO_YOUR_ISSUES = {
  id: 'globalShortcuts.goToYourIssues',
  description: __('Go to your issues'),
  defaultKeys: ['shift+i'],
};

export const GO_TO_YOUR_MERGE_REQUESTS = {
  id: 'globalShortcuts.goToYourMergeRequests',
  description: __('Go to your merge requests'),
  defaultKeys: ['shift+m'],
};

export const GO_TO_YOUR_REVIEW_REQUESTS = {
  id: 'globalShortcuts.goToYourReviewRequests',
  description: __('Go to your review requests'),
  defaultKeys: ['shift+r'],
};

export const GO_TO_YOUR_TODO_LIST = {
  id: 'globalShortcuts.goToYourTodoList',
  description: __('Go to your To-Do List'),
  defaultKeys: ['shift+t'],
};

export const TOGGLE_PERFORMANCE_BAR = {
  id: 'globalShortcuts.togglePerformanceBar',
  description: __('Toggle the Performance Bar'),
  defaultKeys: ['p b'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const HIDE_APPEARING_CONTENT = {
  id: 'globalShortcuts.hideAppearingContent',
  description: __('Hide tooltips or popovers'),
  defaultKeys: ['esc'],
};

export const TOGGLE_SUPER_SIDEBAR = {
  id: 'globalShortcuts.toggleSuperSidebar',
  description: __('Toggle the navigation sidebar'),
  defaultKeys: ['mod+\\'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const TOGGLE_CANARY = {
  id: 'globalShortcuts.toggleCanary',
  description: __('Toggle GitLab Next'),
  defaultKeys: ['g x'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const BOLD_TEXT = {
  id: 'editing.boldText',
  description: __('Bold text'),
  defaultKeys: ['mod+b'],
  customizable: false,
};

export const ITALIC_TEXT = {
  id: 'editing.italicText',
  description: __('Italic text'),
  defaultKeys: ['mod+i'],
  customizable: false,
};

export const STRIKETHROUGH_TEXT = {
  id: 'editing.strikethroughText',
  description: __('Strikethrough text'),
  defaultKeys: ['mod+shift+x'],
  customizable: false,
};

export const LINK_TEXT = {
  id: 'editing.linkText',
  description: __('Link text'),
  defaultKeys: ['mod+k'],
  customizable: false,
};

export const INDENT_LINE = {
  id: 'editing.indentLine',
  description: __('Indent line'),
  defaultKeys: ['mod+]'], // eslint-disable-line @gitlab/require-i18n-strings
  customizable: false,
};

export const OUTDENT_LINE = {
  id: 'editing.outdentLine',
  description: __('Outdent line'),
  defaultKeys: ['mod+['], // eslint-disable-line @gitlab/require-i18n-strings
  customizable: false,
};

export const FIND_AND_REPLACE = {
  id: 'editing.findAndReplace',
  description: s__('MarkdownEditor|Find and replace'),
  defaultKeys: ['mod+f'],
  customizable: false,
};

export const TOGGLE_MARKDOWN_PREVIEW = {
  id: 'editing.toggleMarkdownPreview',
  description: __('Toggle Markdown preview'),
  // Note: Ideally, keyboard shortcuts should be made cross-platform by using the special `mod` key
  // instead of binding both `ctrl` and `command` versions of the shortcut.
  // See https://docs.gitlab.com/ee/development/fe_guide/keyboard_shortcuts.html#make-cross-platform-shortcuts.
  // However, this particular shortcut has been in place since before the `mod` key was available.
  // We've chosen to leave this implemented as-is for the time being to avoid breaking people's workflows.
  // See discussion in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45308#note_527490548.
  defaultKeys: ['ctrl+shift+p', 'command+shift+p'],
};

/**
 * @keydown.up event is handled here: https://gitlab.com/gitlab-org/gitlab/-/blob/f3e807cdff5cf25765894163b4e92f8b2bcf8a68/app/assets/javascripts/notes/components/comment_form.vue#L379
 */
const EDIT_RECENT_COMMENT = {
  id: 'editing.editRecentComment',
  description: __('Edit your most recent comment in a thread (from an empty textarea)'),
  defaultKeys: ['up'],
};

export const SAVE_CHANGES = {
  id: 'globalShortcuts.saveChanges',
  description: __('Submit/save changes'),
  defaultKeys: ['mod+enter'],
};

export const EDIT_WIKI_PAGE = {
  id: 'wiki.editWikiPage',
  description: __('Edit wiki page'),
  defaultKeys: ['e'],
};

export const REPO_GRAPH_SCROLL_LEFT = {
  id: 'repositoryGraph.scrollLeft',
  description: __('Scroll left'),
  defaultKeys: ['left', 'h'],
};

export const REPO_GRAPH_SCROLL_RIGHT = {
  id: 'repositoryGraph.scrollRight',
  description: __('Scroll right'),
  defaultKeys: ['right', 'l'],
};

export const REPO_GRAPH_SCROLL_UP = {
  id: 'repositoryGraph.scrollUp',
  description: __('Scroll up'),
  defaultKeys: ['up', 'k'],
};

export const REPO_GRAPH_SCROLL_DOWN = {
  id: 'repositoryGraph.scrollDown',
  description: __('Scroll down'),
  defaultKeys: ['down', 'j'],
};

export const REPO_GRAPH_SCROLL_TOP = {
  id: 'repositoryGraph.scrollToTop',
  description: __('Scroll to top'),
  defaultKeys: ['shift+up', 'shift+k'],
};

export const REPO_GRAPH_SCROLL_BOTTOM = {
  id: 'repositoryGraph.scrollToBottom',
  description: __('Scroll to bottom'),
  defaultKeys: ['shift+down', 'shift+j'],
};

export const GO_TO_PROJECT_OVERVIEW = {
  id: 'project.goToOverview',
  description: __("Go to the project's overview page"),
  defaultKeys: ['g o'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_ACTIVITY_FEED = {
  id: 'project.goToActivityFeed',
  description: __("Go to the project's activity feed"),
  defaultKeys: ['g v'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_RELEASES = {
  id: 'project.goToReleases',
  description: __('Go to releases'),
  defaultKeys: ['g r'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_FILES = {
  id: 'project.goToFiles',
  description: __('Go to files'),
  defaultKeys: ['g f'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const START_SEARCH_PROJECT_FILE = {
  id: 'project.startSearchFile',
  description: __('Go to find file'),
  defaultKeys: ['t'],
};

export const GO_TO_PROJECT_COMMITS = {
  id: 'project.goToCommits',
  description: __('Go to commits'),
  defaultKeys: ['g c'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_REPO_GRAPH = {
  id: 'project.goToRepoGraph',
  description: __('Go to repository graph'),
  defaultKeys: ['g n'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_REPO_CHARTS = {
  id: 'project.goToRepoCharts',
  description: __('Go to repository charts'),
  defaultKeys: ['g d'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_ISSUES = {
  id: 'project.goToIssues',
  description: __('Go to issues'),
  defaultKeys: ['g i'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const NEW_ISSUE = {
  id: 'project.newIssue',
  description: __('New issue'),
  defaultKeys: ['i'],
};

export const GO_TO_PROJECT_ISSUE_BOARDS = {
  id: 'project.goToIssueBoards',
  description: __('Go to issue boards'),
  defaultKeys: ['g b'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_MERGE_REQUESTS = {
  id: 'project.goToMergeRequests',
  description: __('Go to merge requests'),
  defaultKeys: ['g m'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_PIPELINES = {
  id: 'project.goToPipelines',
  description: __('Go to pipelines'),
  defaultKeys: ['g p'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_JOBS = {
  id: 'project.goToJobs',
  description: __('Go to jobs'),
  defaultKeys: ['g j'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_ENVIRONMENTS = {
  id: 'project.goToEnvironments',
  description: __('Go to environments'),
  defaultKeys: ['g e'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_KUBERNETES = {
  id: 'project.goToKubernetes',
  description: __('Go to kubernetes'),
  defaultKeys: ['g k'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_SNIPPETS = {
  id: 'project.goToSnippets',
  description: __('Go to snippets'),
  defaultKeys: ['g s'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_WIKI = {
  id: 'project.goToWiki',
  description: __('Go to wiki'),
  defaultKeys: ['g w'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const GO_TO_PROJECT_WEBIDE = {
  id: 'project.goToWebIDE',
  description: __('Open in Web IDE'),
  defaultKeys: ['.'],
};

export const PROJECT_FILES_MOVE_SELECTION_UP = {
  id: 'projectFiles.moveSelectionUp',
  description: __('Move selection up'),
  defaultKeys: ['up'],
};

export const PROJECT_FILES_MOVE_SELECTION_DOWN = {
  id: 'projectFiles.moveSelectionDown',
  description: __('Move selection down'),
  defaultKeys: ['down'],
};

export const PROJECT_FILES_OPEN_SELECTION = {
  id: 'projectFiles.openSelection',
  description: __('Open Selection'),
  defaultKeys: ['enter'],
};

export const PROJECT_FILES_GO_BACK = {
  id: 'projectFiles.goBack',
  description: __('Go back (while searching for files)'),
  defaultKeys: ['esc'],
};

export const PROJECT_FILES_GO_TO_PERMALINK = {
  id: 'projectFiles.goToFilePermalink',
  description: __('Go to file permalink (while viewing a file)'),
  defaultKeys: ['y'],
};

export const PROJECT_FILES_GO_TO_COMPARE = {
  id: 'projectFiles.goToCompare',
  description: __('Compare Branches'),
  defaultKeys: ['shift+c'],
};

export const ISSUABLE_COMMENT_OR_REPLY = {
  id: 'issuables.commentReply',
  description: __('Comment/Reply (quoting selected text)'),
  defaultKeys: ['r'],
};

export const ISSUABLE_EDIT_DESCRIPTION = {
  id: 'issuables.editDescription',
  description: __('Edit description'),
  defaultKeys: ['e'],
};

export const ISSUABLE_CHANGE_LABEL = {
  id: 'issuables.changeLabel',
  description: __('Change label'),
  defaultKeys: ['l'],
};

export const ISSUABLE_COPY_REF = {
  id: 'issuables.copyIssuableRef',
  description: __('Copy reference'),
  defaultKeys: ['c r'], // eslint-disable-line @gitlab/require-i18n-strings
};

export const ISSUE_MR_CHANGE_ASSIGNEE = {
  id: 'issuesMRs.changeAssignee',
  description: __('Change assignee'),
  defaultKeys: ['a'],
};

export const ISSUE_MR_CHANGE_MILESTONE = {
  id: 'issuesMRs.changeMilestone',
  description: __('Change milestone'),
  defaultKeys: ['m'],
};

export const MR_NEXT_FILE_IN_DIFF = {
  id: 'mergeRequests.nextFileInDiff',
  description: __('Next file in diff'),
  defaultKeys: [']', 'j'],
};

export const MR_PREVIOUS_FILE_IN_DIFF = {
  id: 'mergeRequests.previousFileInDiff',
  description: __('Previous file in diff'),
  defaultKeys: ['[', 'k'],
};

export const MR_GO_TO_FILE = {
  id: 'mergeRequests.goToFile',
  description: __('Go to file'),
  defaultKeys: ['mod+p', 't'],
  customizable: false,
};

export const MR_TOGGLE_FILE_BROWSER = {
  id: 'mergeRequests.toggleFileBrowser',
  description: __('Toggle file browser'),
  defaultKeys: ['f'],
  customizable: false,
};

export const MR_ADD_TO_REVIEW = {
  id: 'mergeRequests.addToReview',
  description: __('Add your comment to a review'),
  defaultKeys: ['mod+enter'],
  customizable: false,
};

export const MR_ADD_COMMENT_NOW = {
  id: 'mergeRequests.addCommentNow',
  description: __('Publish your comment immediately'),
  defaultKeys: ['shift+mod+enter'],
  customizable: false,
};

export const MR_NEXT_UNRESOLVED_DISCUSSION = {
  id: 'mergeRequests.nextUnresolvedDiscussion',
  description: __('Next unresolved thread'),
  defaultKeys: ['n'],
};

export const MR_PREVIOUS_UNRESOLVED_DISCUSSION = {
  id: 'mergeRequests.previousUnresolvedDiscussion',
  description: __('Previous unresolved thread'),
  defaultKeys: ['p'],
};

export const MR_COPY_SOURCE_BRANCH_NAME = {
  id: 'mergeRequests.copySourceBranchName',
  description: __('Copy source branch name'),
  defaultKeys: ['b'],
};

export const MR_EXPAND_ALL_FILES = {
  id: 'mergeRequests.expandAllFiles',
  description: __('Expand all files'),
  defaultKeys: [';'],
};

export const MR_COLLAPSE_ALL_FILES = {
  id: 'mergeRequests.collapseAllFiles',
  description: __('Collapse all files'),
  // eslint-disable-next-line @gitlab/require-i18n-strings
  defaultKeys: ['shift+;'],
};

export const MR_COMMITS_NEXT_COMMIT = {
  id: 'mergeRequestCommits.nextCommit',
  description: __('Next commit'),
  defaultKeys: ['c'],
};

export const MR_COMMITS_PREVIOUS_COMMIT = {
  id: 'mergeRequestCommits.previousCommit',
  description: __('Previous commit'),
  defaultKeys: ['x'],
};

export const ISSUE_NEXT_DESIGN = {
  id: 'issues.nextDesign',
  description: __('Next design'),
  defaultKeys: ['right'],
};

export const ISSUE_PREVIOUS_DESIGN = {
  id: 'issues.previousDesign',
  description: __('Previous design'),
  defaultKeys: ['left'],
};

export const ISSUE_CLOSE_DESIGN = {
  id: 'issues.closeDesign',
  description: __('Close design'),
  defaultKeys: ['esc'],
};

export const SIDEBAR_CLOSE_WIDGET = {
  id: 'sidebar.closeWidget',
  description: __('Close sidebar widget'),
  defaultKeys: ['esc'],
};

/**
 * Legacy Web IDE uses the same shortcuts as MR_GO_TO_FILE, from this shared component:
 * https://gitlab.com/gitlab-org/gitlab/-/blob/f3e807cdff5cf25765894163b4e92f8b2bcf8a68/app/assets/javascripts/vue_shared/components/file_finder/index.vue#L6
 */
const WEB_IDE_GO_TO_FILE = {
  id: 'webIDE.goToFile',
  description: __('Go to file'),
  defaultKeys: ['mod+p', 't'],
  customizable: false /* customize MR_GO_TO_FILE instead */,
};

/**
 * Legacy Web IDE uses @keydown.ctrl.enter and @keydown.meta.enter events here:
 * https://gitlab.com/gitlab-org/gitlab/-/blob/f3e807cdff5cf25765894163b4e92f8b2bcf8a68/app/assets/javascripts/ide/components/commit_sidebar/message_field.vue#L122-123
 */
const WEB_IDE_COMMIT = {
  id: 'webIDE.commit',
  description: __('Commit (when editing commit message)'),
  defaultKeys: ['mod+enter'],
  customizable: false,
};
// All keybinding groups
const GLOBAL_SHORTCUTS_GROUP = {
  id: 'globalShortcuts',
  name: __('Global Shortcuts'),
  keybindings: [
    TOGGLE_KEYBOARD_SHORTCUTS_DIALOG,
    GO_TO_YOUR_PROJECTS,
    GO_TO_YOUR_GROUPS,
    GO_TO_ACTIVITY_FEED,
    GO_TO_MILESTONE_LIST,
    GO_TO_YOUR_SNIPPETS,
    START_SEARCH,
    FOCUS_FILTER_BAR,
    GO_TO_YOUR_ISSUES,
    GO_TO_YOUR_MERGE_REQUESTS,
    GO_TO_YOUR_REVIEW_REQUESTS,
    GO_TO_YOUR_TODO_LIST,
    TOGGLE_PERFORMANCE_BAR,
    HIDE_APPEARING_CONTENT,
    TOGGLE_SUPER_SIDEBAR,
  ],
};

export const EDITING_SHORTCUTS_GROUP = {
  id: 'editing',
  name: __('Editing'),
  keybindings: [
    BOLD_TEXT,
    ITALIC_TEXT,
    STRIKETHROUGH_TEXT,
    LINK_TEXT,
    TOGGLE_MARKDOWN_PREVIEW,
    FIND_AND_REPLACE,
    EDIT_RECENT_COMMENT,
    SAVE_CHANGES,
  ],
};

const WIKI_SHORTCUTS_GROUP = {
  id: 'wiki',
  name: __('Wiki'),
  keybindings: [EDIT_WIKI_PAGE],
};

const REPOSITORY_GRAPH_SHORTCUTS_GROUP = {
  id: 'repositoryGraph',
  name: __('Repository Graph'),
  keybindings: [
    REPO_GRAPH_SCROLL_LEFT,
    REPO_GRAPH_SCROLL_RIGHT,
    REPO_GRAPH_SCROLL_UP,
    REPO_GRAPH_SCROLL_DOWN,
    REPO_GRAPH_SCROLL_TOP,
    REPO_GRAPH_SCROLL_BOTTOM,
  ],
};

const PROJECT_SHORTCUTS_GROUP = {
  id: 'project',
  name: __('Project'),
  keybindings: [
    GO_TO_PROJECT_OVERVIEW,
    GO_TO_PROJECT_ACTIVITY_FEED,
    GO_TO_PROJECT_RELEASES,
    GO_TO_PROJECT_FILES,
    START_SEARCH_PROJECT_FILE,
    GO_TO_PROJECT_COMMITS,
    GO_TO_PROJECT_REPO_GRAPH,
    GO_TO_PROJECT_REPO_CHARTS,
    GO_TO_PROJECT_ISSUES,
    NEW_ISSUE,
    GO_TO_PROJECT_ISSUE_BOARDS,
    GO_TO_PROJECT_MERGE_REQUESTS,
    GO_TO_PROJECT_PIPELINES,
    GO_TO_PROJECT_JOBS,
    GO_TO_PROJECT_ENVIRONMENTS,
    GO_TO_PROJECT_KUBERNETES,
    GO_TO_PROJECT_SNIPPETS,
    GO_TO_PROJECT_WIKI,
    GO_TO_PROJECT_WEBIDE,
  ],
};

const PROJECT_FILES_SHORTCUTS_GROUP = {
  id: 'projectFiles',
  name: __('Project Files'),
  keybindings: [
    PROJECT_FILES_MOVE_SELECTION_UP,
    PROJECT_FILES_MOVE_SELECTION_DOWN,
    PROJECT_FILES_OPEN_SELECTION,
    PROJECT_FILES_GO_BACK,
    PROJECT_FILES_GO_TO_PERMALINK,
    PROJECT_FILES_GO_TO_COMPARE,
  ],
};

const ISSUABLE_SHORTCUTS_GROUP = {
  id: 'issuables',
  name: __('Epics, issues, and merge requests'),
  keybindings: [
    ISSUABLE_COMMENT_OR_REPLY,
    ISSUABLE_EDIT_DESCRIPTION,
    ISSUABLE_CHANGE_LABEL,
    ISSUABLE_COPY_REF,
  ],
};

const ISSUE_MR_SHORTCUTS_GROUP = {
  id: 'issuesMRs',
  name: __('Issues and merge requests'),
  keybindings: [ISSUE_MR_CHANGE_ASSIGNEE, ISSUE_MR_CHANGE_MILESTONE],
};

const MR_SHORTCUTS_GROUP = {
  id: 'mergeRequests',
  name: __('Merge requests'),
  keybindings: [
    MR_NEXT_FILE_IN_DIFF,
    MR_PREVIOUS_FILE_IN_DIFF,
    MR_GO_TO_FILE,
    MR_NEXT_UNRESOLVED_DISCUSSION,
    MR_PREVIOUS_UNRESOLVED_DISCUSSION,
    MR_COPY_SOURCE_BRANCH_NAME,
    MR_TOGGLE_FILE_BROWSER,
    MR_ADD_TO_REVIEW,
    MR_ADD_COMMENT_NOW,
  ],
};

const MR_COMMITS_SHORTCUTS_GROUP = {
  id: 'mergeRequestCommits',
  name: __('Merge request commits'),
  keybindings: [MR_COMMITS_NEXT_COMMIT, MR_COMMITS_PREVIOUS_COMMIT],
};

const ISSUES_SHORTCUTS_GROUP = {
  id: 'issues',
  name: __('Issues'),
  keybindings: [ISSUE_NEXT_DESIGN, ISSUE_PREVIOUS_DESIGN, ISSUE_CLOSE_DESIGN],
};

const WEB_IDE_SHORTCUTS_GROUP = {
  id: 'webIDE',
  name: __('Legacy Web IDE'),
  keybindings: [WEB_IDE_GO_TO_FILE, WEB_IDE_COMMIT],
};

export const MISC_SHORTCUTS_GROUP = {
  id: 'misc',
  name: __('Miscellaneous'),
  keybindings: [TOGGLE_CANARY],
};

/** All keybindings, grouped and ordered with descriptions */
export const keybindingGroups = [
  GLOBAL_SHORTCUTS_GROUP,
  EDITING_SHORTCUTS_GROUP,
  WIKI_SHORTCUTS_GROUP,
  REPOSITORY_GRAPH_SHORTCUTS_GROUP,
  PROJECT_SHORTCUTS_GROUP,
  PROJECT_FILES_SHORTCUTS_GROUP,
  ISSUABLE_SHORTCUTS_GROUP,
  ISSUE_MR_SHORTCUTS_GROUP,
  MR_SHORTCUTS_GROUP,
  MR_COMMITS_SHORTCUTS_GROUP,
  ISSUES_SHORTCUTS_GROUP,
  WEB_IDE_SHORTCUTS_GROUP,
  MISC_SHORTCUTS_GROUP,
];

/**
 * Gets keyboard shortcuts associated with a command
 *
 * @param {Object} command The command object. All command objects are
 *     available as imports from this file.
 * @param {string} command.id
 * @param {string[]} command.defaultKeys
 * @param {boolean} [command.customizable]
 *
 * @returns {string[]} An array of keyboard shortcut strings bound to the command
 *
 * @example
 * import { keysFor, TOGGLE_PERFORMANCE_BAR } from '~/behaviors/shortcuts/keybindings'
 *
 * Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), handler);
 */
export const keysFor = (command) => {
  if (!isCustomizable(command)) {
    // if the command is defined with `customizable: false`,
    // don't allow this command to be customized.
    return command.defaultKeys;
  }

  return getCustomizations()[command.id] || command.defaultKeys;
};
