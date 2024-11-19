---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Settings and commands in the GitLab Workflow extension for VS Code."
---

# GitLab Workflow extension settings and commands

## Command Palette commands

In VS Code, trigger these commands from the
[Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette).

- [`GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)`](index.md#search-issues-and-merge-requests)
- [`GitLab: Compare Current Branch with Default Branch`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#compare-with-default-branch):
  Compare your branch with the repository's default branch and view changes on GitLab.
- `GitLab: Copy Link to Active File on GitLab`
- `GitLab: Create New Issue on Current Project`
- `GitLab: Create New Merge Request on Current Project`: Open the merge request page to create a merge request.
- [`GitLab: Create Snippet`](index.md#create-a-snippet): Create a public, internal, or private snippet
  from an entire file or selection.
- [`GitLab: Create Snippet Patch`](index.md#create-a-patch-file): Create a `.patch` file from the entire file, or a selection.
- [`GitLab: Insert Snippet`](index.md#insert-a-snippet): Insert a single-file or multi-file project snippet.
- [`GitLab: Open Active File on GitLab`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#open-active-file) -
  View active file on GitLab with highlighting active line number and selected text block.
- `GitLab: Open Current Project on GitLab`
- `GitLab: Open Merge Request for Current Branch`
- [`GitLab: Open Remote Repository`](remote_urls.md): Browse a remote GitLab repository.
- `GitLab: Remove Account from VS Code`
- [`GitLab: Search Project Issues (Supports Filters)`](index.md#search-issues-and-merge-requests).
- [`GitLab: Search Project Merge Requests (Supports Filters)`](index.md#search-issues-and-merge-requests).
- `GitLab: Show Issues Assigned to Me`: Open issues assigned to you on GitLab.
- `GitLab: Show Merge Requests Assigned to Me`: Open merge requests assigned to you on GitLab.
- [`GitLab: Show Merged GitLab CI/CD Config`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#show-merged-gitlab-cicd-configuration):
  Show a preview of the GitLab CI/CD configuration file `.gitlab-ci.yml` with all includes resolved.
- `GitLab: Toggle Code Suggestions`
- `GitLab: Toggle Code Suggestions for current language`
- [`GitLab: Validate GitLab CI/CD Config`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#validate-gitlab-cicd-configuration):
  Test the GitLab CI/CD configuration file `.gitlab-ci.yml`.

### Command integrations

This extension also integrates with these commands:

- `Git: Clone`: Search for and clone projects for every GitLab instance you set up. For more information, see:
  - [Clone GitLab projects](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#clone-gitlab-projects)
    in the extension documentation.
  - [Cloning a repository](https://code.visualstudio.com/docs/sourcecontrol/overview#_cloning-a-repository)
    in the VS Code documentation.
- `Git: Add Remote...`: Add existing projects as remotes from every GitLab instance you set up.

## Extension settings

To learn how to change settings in VS Code, see the VS Code documentation for
[User and Workspace Settings](https://code.visualstudio.com/docs/getstarted/settings).

If you use self-signed certificates to connect to your GitLab instance, read the community-contributed
[settings for self-signed certificates](troubleshooting.md#configure-self-signed-certificates).

| Setting | Default | Information |
| ------- | ------- | ----------- |
| `gitlab.customQueries` | Not applicable | Defines the search queries that retrieves the items shown on the GitLab Panel. For more information, see [Custom Queries documentation](custom_queries.md). |
| `gitlab.debug` | false | Set to `true` to enable debug mode. Debug mode improves error stack traces because the extension uses source maps to understand minified code. Debug mode also shows debug log messages in the [extension logs](troubleshooting.md#view-log-files). |
| `gitlab.duo.enabledWithoutGitlabProject` | true | Set to `true` to keep GitLab Duo features _enabled_ if the extension can't retrieve the project's `duoFeaturesEnabledForProject` setting. When `false`, all GitLab Duo features are disabled if the extension can't retrieve the project's `duoFeaturesEnabledForProject` setting. See [`duoFeaturesEnabledForProject` setting](#duofeaturesenabledforproject). |
| `gitlab.duoCodeSuggestions.additionalLanguages` | Not applicable | (Experimental.) To expand the list of [officially supported languages](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages) for Code Suggestions, provide an array of the [language identifiers](https://code.visualstudio.com/docs/languages/identifiers#_known-language-identifiers). Code suggestions quality for the added languages might not be optimal. |
| `gitlab.duoCodeSuggestions.enabled` | true | Toggle to enable or disable AI-assisted code suggestions. |
| `gitlab.duoCodeSuggestions.enabledSupportedLanguages` | Not applicable | The [supported languages](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages) for which to enable Code Suggestions. By default, all supported languages are enabled. |
| `gitlab.duoCodeSuggestions.openTabsContext` | true | Toggle to enable or disable sending of context across open tabs to improve Code Suggestions. |
| `gitlab.pipelineGitRemoteName` | null | The name of the Git remote name corresponding to the GitLab repository with your pipelines. If set to `null` or missing, then the extension uses the same remote as for the non-pipeline features. |
| `gitlab.showPipelineUpdateNotifications` | false | Set to `true` to show an alert when a pipeline completes. |

### `duoFeaturesEnabledForProject`

The `duoFeaturesEnabledForProject` setting is unavailable if:

- The project is not set up in the extension.
- The project is on a different GitLab instance than your current account.
- The file or folder you are working with isn't part of any GitLab project you have access to.
