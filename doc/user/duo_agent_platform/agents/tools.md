---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agent tools
---

The following tools are available to custom agents.

<!-- markdownlint-disable MD044 -->

## Tools available in the Web UI and IDE

| Name | Tool | Description |
|------|------|-------------|
| Add New Task | `add_new_task` | Add a task. |
| Build Review Merge Request Context | `build_review_merge_request_context` | Build comprehensive merge request context for code review. |
| Ci Linter | `ci_linter` | Validate CI/CD YAML configurations against CI/CD syntax rules. |
| Confirm Vulnerability | `confirm_vulnerability` | Change the state of a vulnerability in a project to `CONFIRMED`. |
| Create Commit | `create_commit` | Create a commit with multiple file actions in a repository. |
| Create Epic | `create_epic` | Create epics in a group. |
| Create Issue | `create_issue` | Create issues in a project. |
| Create Issue Note | `create_issue_note` | Add notes to an issue. |
| Create Merge Request | `create_merge_request` | Create merge requests in a project. |
| Create Merge Request Note | `create_merge_request_note` | Add notes to a merge request. Quick actions are not supported. |
| Create Plan | `create_plan` | Create a list of tasks. |
| Create Vulnerability Issue | `create_vulnerability_issue` | Create an issue linked to security vulnerabilities in a project. |
| Create Work Item | `create_work_item` | Create a work item in a group or project. Quick actions are not supported. |
| Create Work Item Note | `create_work_item_note` | Add a note to a work item. Quick actions are not supported. |
| Dismiss Vulnerability | `dismiss_vulnerability` | Dismiss a security vulnerability in a project. |
| Extract Lines From Text | `extract_lines_from_text` | Extract specific lines from text. |
| Get Commit | `get_commit` | Get a commit from a project. |
| Get Commit Comments | `get_commit_comments` | Get the comments of a commit in a project. |
| Get Commit Diff | `get_commit_diff` | Get the diff of a commit in a project. |
| Get Current User | `get_current_user` | Get the following information about the current user: username, job title, and preferred languages. |
| Get Epic | `get_epic` | Get an epic in a group. |
| Get Epic Note | `get_epic_note` | Get a note from an epic. |
| Get Issue | `get_issue` | Get an issue from a project. |
| Get Issue Note | `get_issue_note` | Get a note from an issue. |
| Get Job Logs | `get_job_logs` | Get the trace for a job. |
| Get Merge Request | `get_merge_request` | Get details about a merge request. |
| Get Pipeline Errors | `get_pipeline_errors` | Get the logs for failed jobs from the latest pipeline of a merge request. |
| Get Pipeline Failing Jobs | `get_pipeline_failing_jobs` | Get the IDs for failed jobs in a pipeline. |
| Get Plan | `get_plan` | Get a list of tasks. |
| Get Previous Session Context | `get_previous_session_context` | Get context from a previous session. |
| Get Project | `get_project` | Get details about a project. |
| Get Repository File | `get_repository_file` | Get the contents of a file from a remote repository. |
| Get Security Finding Details | `get_security_finding_details` | Get the details of a potential vulnerability by its ID and the ID of the pipeline scan that identified it. |
| Get Vulnerability Details | `get_vulnerability_details` | Get the following information about a vulnerability specified by ID: basic vulnerability information, location details, CVE enrichment data, detection pipeline information, and detailed vulnerability report data. |
| Get Wiki Page | `get_wiki_page` | Get a wiki page from a project or group, including all its comments. |
| Get Work Item | `get_work_item` | Get a work item from a group or project. |
| Get Work Item Notes | `get_work_item_notes` | Get all notes for a work item. |
| GitLab API Get | `gitlab_api_get` | Make read-only GET requests to any REST API endpoint. |
| GitLab Blob Search | `gitlab_blob_search` | Search for the contents of files in a group, project, or instance. To search across a group or in an instance, you must turn on either [advanced](../../../integration/advanced_search/elasticsearch.md#enable-code-search-with-advanced-search) or [exact code](../../../integration/zoekt/_index.md#enable-exact-code-search) search.  |
| GitLab Commit Search | `gitlab_commit_search` | Search for commits in a project or group. |
| GitLab Documentation Search | `gitlab_documentation_search` | Search the GitLab documentation for information. |
| GitLab GraphQL | `gitlab_graphql` | Execute read-only GraphQL queries against the GraphQL API. |
| GitLab Group Project Search | `gitlab_group_project_search` | Search for projects in a group. |
| GitLab Issue Search | `gitlab_issue_search` | Search for issues in a project or group. |
| GitLab Merge Request Search | `gitlab_merge_request_search` | Search for merge requests in a project or group. |
| GitLab Milestone Search | `gitlab_milestone_search` | Search for milestones in a project or group. |
| GitLab Note Search | `gitlab_note_search` | Search for notes in a project. |
| GitLab User Search | `gitlab__user_search` | Search for users in a project or group. |
| GitLab Wiki Blob Search | `gitlab_wiki_blob_search` | Search the contents of wikis in a project or group. |
| Link Vulnerability To Issue | `link_vulnerability_to_issue` | Link an issue to security vulnerabilities in a project. |
| Link Vulnerability To Merge Request | `link_vulnerability_to_merge_request` | Link a security vulnerability to a merge request in a project using GraphQL. |
| List All Merge Request Notes | `list_all_merge_request_notes` | List all notes on a merge request. |
| List Commits | `list_commits` | List commits in a project. |
| List Epic Notes | `list_epic_notes` | List all notes for an epic. |
| List Epics | `list_epics` | List all epics of a group and its subgroups. |
| List Group Audit Events | `list_group_audit_events` | List audit events for a group. You must have the Owner role to access group audit events. |
| List Instance Audit Events | `list_instance_audit_events` | List instance-level audit events. You must be an administrator to see instance audit events. |
| List Issue Notes | `list_issue_notes` | List all notes on an issue. |
| List Issues | `list_issues` | List all issues in a project. |
| List Merge Request Diffs | `list_merge_request_diffs` | List the diffs of changed files in a merge request. |
| List Project Audit Events | `list_project_audit_events` | List audit events for a project. You must have the Owner role to access project audit events. |
| List Repository Tree | `list_repository_tree` | List files and directories in a repository. |
| List Security Findings | `list_security_findings` | List ephemeral security findings from a specific pipeline security scan. |
| List Vulnerabilities | `list_vulnerabilities` | List security vulnerabilities in a project. |
| List Work Items | `list_work_items` | List work items in a project or group. |
| Post GitLab Duo Code Review | `post_duo_code_review` | Post a GitLab Duo code review to a merge request. |
| Post SAST FP Analysis To GitLab | `post_sast_fp_analysis_to_gitlab` | Post SAST false positive detection analysis results. |
| Remove Task | `remove_task` | Remove a task from a list of tasks. |
| Revert To Detected Vulnerability | `revert_to_detected_vulnerability` | Revert a vulnerability's state to `detected`. |
| Run GLQL Query | `run_glql_query` | Execute GLQL queries for work items, epics, and merge requests. |
| Run Tests | `run_tests` | Execute test commands for any language or framework. |
| Set Task Status | `set_task_status` | Set the status of a task. |
| Update Epic | `update_epic` | Update an epic in a group. |
| Update Issue | `update_issue` | Update an issue in a project. |
| Update Merge Request | `update_merge_request` | Update a merge request. You can change the target branch, edit the title, or even close the MR. |
| Update Task Description | `update_task_description` | Update the description of a task. |
| Update Vulnerability Severity | `update_vulnerability_severity` | Update the severity level of vulnerabilities in a project. |
| Update Work Item | `update_work_item` | Update an existing work item in a group or project. Quick actions are not supported. |

## Tools available in the IDE only

| Name | Tool | Description |
|------|------|-------------|
| Create File With Contents | `create_file_with_contents` | Create a file and write content to it. |
| Edit File | `edit_file` | Edit existing files. |
| Find Files | `find_files` | Recursively find files in a project. |
| Grep | `grep` | Recursively search for text patterns in files. This tool respects `.gitignore` file rules. |
| List Dir | `list_dir` | List files in a directory relative to the root of the project. |
| Mkdir | `mkdir` | Create a directory in the current working tree. |
| Read File | `read_file` | Read the contents of a file. |
| Read Files | `read_files` | Read the contents of files. |
| Run Command | `run_command` | Run bash commands in the current working directory. Git commands are not supported. |
| Run Git Command | `run_git_command` | Run Git commands in the current working directory. |
