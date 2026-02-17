---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Agent tools
---

The following tools are available to custom agents.

<!-- markdownlint-disable MD044 -->

| Name | Description |
|-------|-------------|
| Gitlab Blob Search | Search for the contents of files in a group or project. |
| Ci Linter | Validate CI/CD YAML configurations against CI/CD syntax rules. |
| Run Git Command | Run Git commands in the current working directory. |
| Gitlab Commit Search | Search for commits in a project or group. |
| Create Epic | Create epics in a group. |
| Create Issue | Create issues in a project. |
| Create Issue Note | Add notes to an issue. |
| Create Merge Request | Create merge requests in a project. |
| Create Merge Request Note | Add notes to a merge request. Quick actions are not supported. |
| Edit File | Edit existing files. |
| Find Files | Recursively find files in a project. |
| Get Commit | Get a commit from a project. |
| Get Commit Comments | Get the comments of a commit in a project. |
| Get Commit Diff | Get the diff of a commit in a project. |
| Get Epic | Get an epic in a group. |
| Get Epic Note | Get a note from an epic. |
| Get Issue | Get an issue from a project. |
| Get Issue Note | Get a note from an issue. |
| Get Job Logs | Get the trace for a job. |
| Get Merge Request | Get details about a merge request. |
| Get Pipeline Errors | Get the logs for failed jobs from the latest pipeline of a merge request. |
| Get Project | Get details about a project. |
| Get Repository File | Get the contents of a file from a remote repository. |
| Grep | Recursively search for text patterns in files. This tool respects `.gitignore` file rules. |
| Gitlab Group Project Search | Search for projects in a group. |
| Gitlab Issue Search | Search for issues in a project or group. |
| List All Merge Request Notes | List all notes on a merge request. |
| List Commits | List commits in a project. |
| List Dir | List files in a directory relative to the root of the project. |
| List Epic Notes | List all notes for an epic. |
| List Epics | List all epics of a group and its subgroups. |
| List Issue Notes | List all notes on an issue. |
| List Issues | List all issues in a project. |
| List Merge Request Diffs | List the diffs of changed files in a merge request. |
| Gitlab Merge Request Search | Search for merge requests in a project or group. |
| Gitlab Milestone Search | Search for milestones in a project or group. |
| Mkdir | Create a directory in the current working tree. |
| Gitlab Note Search | Search for notes in a project. |
| Read File | Read the contents of a file. |
| Run Command | Run bash commands in the current working directory. Git commands are not supported. |
| Set Task Status | Set the status of a task. |
| Update Epic | Update an epic in a group. |
| Update Issue | Update an issue in a project. |
| Update Merge Request | Update a merge request. You can change the target branch, edit the title, or even close the MR. |
| Gitlab User Search | Search for users in a project or group. |
| Gitlab Wiki Blob Search | Search the contents of wikis in a project or group. |
| Create File With Contents | Create a file and write content to it. |
| Gitlab Documentation Search | Search the GitLab documentation for information. |
| Get Current User | Get the following information about the current user: username, job title, and preferred languages. |
| Add New Task | Add a task. |
| Create Vulnerability Issue | Create an issue linked to security vulnerabilities in a project. You must specify the project by its full path. For example, 'group/subgroup/project'. You can create an issue linked to vulnerabilities by ID. You can provide up to 100 IDs at once. |
| Read Files | Read the contents of files. |
| Get Work Item | Get a work item from a group or project. You must provide either the `group_id/project_id` and `work_item_iid`, or the URL to the work item. |
| Create Plan | Create a list of tasks. |
| Get Plan | Get a list of tasks. |
| Update Task Description | Update the description of a task. |
| Revert To Detected Vulnerability | Revert a vulnerability's state to `detected`. You can provide an optional comment with a reason for reverting. You must identify the vulnerability by its ID. |
| Get Previous Session Context | Get context from a previous session. |
| List Repository Tree | List files and directories in a repository. To identify a project you must provide either a `project_id` or the URL to the project. You can specify a path to get contents of a subdirectory or a specific ref. |
| Create Work Item Note | Add a note to a work item. Quick actions are not supported. |
| Remove Task | Remove a task from a list of tasks. You must specify the task by its ID. |
| Update Vulnerability Severity | Update the severity level of vulnerabilities in a project. You must provide the full path of the project. You can provide an optional comment explaining the update. |
| List Project Audit Events | List audit events for a project. You must have the Owner role to access project audit events. |
| List Group Audit Events | List audit events for a group. You must have the Owner role to access group audit events. |
| Link Vulnerability To Issue | Link an issue to security vulnerabilities in a project. You must provide the full path of the project. You can provide up to 100 vulnerability IDs at once. |
| List Instance Audit Events | List instance-level audit events. You must be an administrator to see instance audit events. |
| Get Vulnerability Details | Get the following information about a vulnerability specified by ID: basic vulnerability information, location details, CVE enrichment data, detection pipeline information, and detailed vulnerability report data. |
| Dismiss Vulnerability | Dismiss a security vulnerability in a project. You must provide the full path of the project. You can provide an optional comment explaining the dismissal. |
| Confirm Vulnerability | Change the state of a vulnerability in a project to `CONFIRMED`. |
| Update Work Item | Update an existing work item in a group or project. Quick actions are not supported. |
| List Work Items | List work items in a project or group. |
| Create Commit | Create a commit with multiple file actions in a repository. To identify the project you must provide either a `project_id` the URL to the project. Actions include creating, updating, deleting, moving, or changing file permissions. |
| List Vulnerabilities | List security vulnerabilities in a project. You must provide the full project path. You can filter vulnerabilities by severity level and report type. |
| Get Work Item Notes | Get all notes for a work item. To identify a work item you must provide either a `group_id/project_id` and `work_item_iid`, or the URL to the work item. |
| Create Work Item | Create a work item in a group or project. Quick actions are not supported. |
| Get Wiki Page | Get a wiki page from a project or group, including all its comments. You must provide the slug of the wiki page and either the `project_id` or `group_id`. |
| Get Security Finding Details | Get the details of a potential vulnerability by its ID and the ID of the pipeline scan that identified it. |
| Gitlab Api Get | Make read-only GET requests to any REST API endpoint. Supports both direct API endpoint paths and resource URLs. |
| Gitlab Graphql | Execute read-only GraphQL queries against the GraphQL API. |
| Link Vulnerability To Merge Request | Link a security vulnerability to a merge request in a project using GraphQL. You must provide the full path of the project. The tool supports linking a vulnerability to a merge request by ID. The merge request ID is its global ID. |
| Get Pipeline Failing Jobs | Get the IDs for failed jobs in a pipeline. You can identify a specific pipeline ID, or ask for all failing jobs in a merge request. |
| Run Tests | Execute test commands for any language or framework. |
| Extract Lines From Text | Extract specific lines from text.|
| List Security Findings | List ephemeral security findings from a specific pipeline security scan. |
| Build Review Merge Request Context | Build comprehensive merge request context for code review. Fetches MR details, AI-reviewable diffs, and file contents. |
| Post Sast Fp Analysis To Gitlab | Post SAST false positive detection analysis results. |
| Post Duo Code Review | Post a GitLab Duo code review to a merge request. |
