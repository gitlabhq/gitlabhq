---
type: index, reference
---

# Merge requests

Merge requests allow you to visualize and collaborate on the proposed changes
to source code that exist as commits on a given Git branch.

![Merge request view](img/merge_request.png)

A Merge Request (**MR**) is the basis of GitLab as a code collaboration and version
control platform. It is as simple as the name implies: a _request_ to _merge_ one
branch into another.

## Use cases

A. Consider you are a software developer working in a team:

1. You checkout a new branch, and submit your changes through a merge request
1. You gather feedback from your team
1. You work on the implementation optimizing code with [Code Quality reports](code_quality.md) **(STARTER)**
1. You verify your changes with [JUnit test reports](../../../ci/junit_test_reports.md) in GitLab CI/CD
1. You avoid using dependencies whose license is not compatible with your project with [License Compliance reports](../../application_security/license_compliance/index.md) **(ULTIMATE)**
1. You request the [approval](merge_request_approvals.md) from your manager **(STARTER)**
1. Your manager:
   1. Pushes a commit with their final review
   1. [Approves the merge request](merge_request_approvals.md) **(STARTER)**
   1. Sets it to [merge when pipeline succeeds](merge_when_pipeline_succeeds.md)
1. Your changes get deployed to production with [manual actions](../../../ci/yaml/README.md#whenmanual) for GitLab CI/CD
1. Your implementations were successfully shipped to your customer

B. Consider you're a web developer writing a webpage for your company's website:

1. You checkout a new branch, and submit a new page through a merge request
1. You gather feedback from your reviewers
1. Your changes are previewed with [Review Apps](../../../ci/review_apps/index.md)
1. You request your web designers for their implementation
1. You request the [approval](merge_request_approvals.md) from your manager **(STARTER)**
1. Once approved, your merge request is [squashed and merged](squash_and_merge.md), and [deployed to staging with GitLab Pages](https://about.gitlab.com/blog/2016/08/26/ci-deployment-and-environments/)
1. Your production team [cherry picks](cherry_pick_changes.md) the merge commit into production

## Overview

Merge requests (aka "MRs") display a great deal of information about the changes proposed.
The body of an MR contains its description, along with its widget (displaying information
about CI/CD pipelines, when present), followed by the discussion threads of the people
collaborating with that MR.

MRs also contain navigation tabs from which you can see the discussion happening on the thread,
the list of commits, the list of pipelines and jobs, the code changes and inline code reviews.

## Merge request navigation tabs at the top

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/33813) in GitLab 12.6. This positioning is experimental.

So far, the navigation tabs present in merge requests to display **Discussion**,
**Commits**, **Pipelines**, and **Changes** were located after the merge request
widget.

To facilitate this navigation without having to scroll up and down through the page
to find these tabs, based on user feedback, we are experimenting with a new positioning
of these tabs. They are now located at the top of the merge request, with a new
**Overview** tab, containing the description of the merge request followed by the
widget. Next to **Overview**, you can find **Pipelines**, **Commits**, and **Changes**.

![Merge request tab positions](img/merge_request_tab_position_v12_6.png)

Please note this change is currently behind a feature flag which is enabled by default. For
self-managed instances, it can be disabled through the Rails console by a GitLab
administrator with the following command:

```ruby
Feature.disable(:mr_tabs_position)
```

## Creating merge requests

While making changes to files in the `master` branch of a repository is possible, it is not
the common workflow. In most cases, a user will make changes in a [branch](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell#_git_branching),
then [create a merge request](creating_merge_requests.md) to request that the changes
be merged into another branch (often the `master` branch).

It is then [reviewed](#reviewing-and-managing-merge-requests), possibly updated after
discussions and suggestions, and finally approved and merged into the target branch.
Creating and reviewing merge requests is one of the most fundamental parts of working
with GitLab.

When [creating merge requests](creating_merge_requests.md), there are a number of features
to be aware of:

| Feature                                                                                                                                       | Description                                                                                                                                                                                |
|-----------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Adding patches when creating a merge request via e-mail](creating_merge_requests.md#adding-patches-when-creating-a-merge-request-via-e-mail) | Add commits to a merge request created by e-mail, by adding patches as e-mail attachments.                                                                                                 |
| [Allow collaboration on merge requests across forks](allow_collaboration.md)                                                                  | Allows the maintainers of an upstream project to collaborate on a fork, to make fixes or rebase branches before merging, reducing the back and forth of accepting community contributions. |
| [Assignee](creating_merge_requests.md#assignee)                                                                                               | Add an assignee to indicate who is reviewing or accountable for it.                                                                                                                        |
| [Automatic issue closing](../../project/issues/managing_issues.md#closing-issues-automatically)                                               | Set a merge request to close defined issues automatically as soon as it is merged.                                                                                                         |
| [Create new merge requests by email](creating_merge_requests.md#create-new-merge-requests-by-email)                                           | Create new merge requests by sending an email to a user-specific email address.                                                                                                            |
| [Deleting the source branch](creating_merge_requests.md#deleting-the-source-branch)                                                           | Select the "Delete source branch when merge request accepted" option and the source branch will be deleted when the merge request is merged.                                               |
| [Git push options](../push_options.md)                                                                                                        | Use Git push options to create or update merge requests when pushing changes to GitLab with Git, without needing to use the GitLab interface.                                              |
| [Labels](../../project/labels.md)                                                                                                             | Organize your issues and merge requests consistently throughout the project.                                                                                                               |
| [Merge request approvals](merge_request_approvals.md) **(STARTER)**                                                                           | Set the number of necessary approvals and predefine a list of approvers that will need to approve every merge request in a project.                                                        |
| [Merge Request dependencies](merge_request_dependencies.md) **(PREMIUM)**                                                                     | Specify that a merge request depends on other merge requests, enforcing a desired order of merging.                                                                                        |
| [Merge Requests for Confidential Issues](../issues/confidential_issues.md#merge-requests-for-confidential-issues)                             | Create merge requests to resolve confidential issues for preventing leakage or early release of sensitive data through regular merge requests.                                             |
| [Milestones](../../project/milestones/index.md)                                                                                               | Track merge requests to achieve a broader goal in a certain period of time.                                                                                                                |
| [Multiple assignees](creating_merge_requests.md#multiple-assignees-starter) **(STARTER)**                                                     | Have multiple assignees for merge requests to indicate everyone that is reviewing or accountable for it.                                                                                   |
| [Squash and merge](squash_and_merge.md)                                                                                                       | Squash all changes present in a merge request into a single commit when merging, to allow for a neater commit history.                                                                     |
| [Work In Progress merge requests](work_in_progress_merge_requests.md)                                                                         | Prevent the merge request from being merged before it's ready                                                                                                                              |

## Reviewing and managing merge requests

Once a merge request has been [created](#creating-merge-requests) and submitted, there
are many powerful features that you can use during the review process to make sure only
the changes you want are merged into the repository.

For managers and administrators, it is also important to be able to view and manage
all the merge requests in a group or project. When [reviewing or managing merge requests](reviewing_and_managing_merge_requests.md),
there are a number of features to be aware of:

| Feature                                                                                                                                               | Description                                                                                                                                              |
|-------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Bulk editing merge requests](../../project/bulk_editing.md)                                                                                          | Update the attributes of multiple merge requests simultaneously.                                                                                         |
| [Cherry-pick changes](cherry_pick_changes.md)                                                                                                         | Cherry-pick any commit in the UI by simply clicking the **Cherry-pick** button in a merged merge requests or a commit.                                   |
| [Commenting on any file line in merge requests](reviewing_and_managing_merge_requests.md#commenting-on-any-file-line-in-merge-requests)               | Make comments directly on the exact line of a file you want to talk about.                                                                               |
| [Discuss changes in threads in merge requests reviews](../../discussions/index.md)                                                                    | Keep track of the progress during a code review by making and resolving comments.                                                                        |
| [Fast-forward merge requests](fast_forward_merge.md)                                                                                                  | For a linear Git history and a way to accept merge requests without creating merge commits                                                               |
| [Find the merge request that introduced a change](versions.md)                                                                                        | When viewing the commit details page, GitLab will link to the merge request(s) containing that commit.                                                   |
| [Ignore whitespace changes in Merge Request diff view](reviewing_and_managing_merge_requests.md#ignore-whitespace-changes-in-Merge-Request-diff-view) | Hide whitespace changes from the diff view for a to focus on more important changes.                                                                     |
| [Incrementally expand merge request diffs](reviewing_and_managing_merge_requests.md#incrementally-expand-merge-request-diffs)                         | View the content directly above or below a change, to better understand the context of that change.                                                      |
| [Live preview with Review Apps](reviewing_and_managing_merge_requests.md#live-preview-with-review-apps)                                               | Live preview the changes when Review Apps are configured for your project                                                                                |
| [Merge request diff file navigation](reviewing_and_managing_merge_requests.md#merge-request-diff-file-navigation)                                     | Quickly jump to any changed file within the diff view.                                                                                                   |
| [Merge requests versions](versions.md)                                                                                                                | Select and compare the different versions of merge request diffs                                                                                         |
| [Merge when pipeline succeeds](merge_when_pipeline_succeeds.md)                                                                                       | Set a merge request that looks ready to merge to merge automatically when CI pipeline succeeds.                                                          |
| [Perform a Review](../../discussions/index.md#merge-request-reviews-premium) **(PREMIUM)**                                                            | Start a review in order to create multiple comments on a diff and publish them once you're ready.                                                        |
| [Pipeline status in merge requests](reviewing_and_managing_merge_requests.md#pipeline-status-in-merge-requests)                                       | If using [GitLab CI/CD](../../../ci/README.md), see pre and post-merge pipelines information, and which deployments are in progress.                     |
| [Post-merge pipeline status](reviewing_and_managing_merge_requests.md#post-merge-pipeline-status)                                                     | When a merge request is merged, see the post-merge pipeline status of the branch the merge request was merged into.                                      |
| [Resolve conflicts](resolve_conflicts.md)                                                                                                             | GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.                                                               |
| [Revert changes](revert_changes.md)                                                                                                                   | Revert changes from any commit from within a merge request.                                                                                              |
| [Semi-linear history merge requests](reviewing_and_managing_merge_requests.md#semi-linear-history-merge-requests)                                     | Enable semi-linear history merge requests as another security layer to guarantee the pipeline is passing in the target branch                            |
| [Suggest changes](../../discussions/index.md#suggest-changes)                                                                                         | Add suggestions to change the content of merge requests directly into merge request threads, and easily apply them to the codebase directly from the UI. |
| [Time Tracking](../time_tracking.md#time-tracking)                                                                                                    | Add a time estimation and the time spent with that merge request.                                                                                        |
| [View changes between file versions](reviewing_and_managing_merge_requests.md#view-changes-between-file-versions)                                     | View what will be changed when a merge request is merged.                                                                                                |
| [View group merge requests](reviewing_and_managing_merge_requests.md#view-merge-requests-for-all-projects-in-a-group)                                 | List and view the merge requests within a group.                                                                                                         |
| [View project merge requests](reviewing_and_managing_merge_requests.md#view-project-merge-requests)                                                   | List and view the merge requests within a project.                                                                                                       |

## Testing and reports in merge requests

GitLab has the ability to test the changes included in a merge request, and can display
or link to useful information directly in the merge request page:

| Feature                                                                                                | Description                                                                                                                                                                                               |
|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Browser Performance Testing](browser_performance_testing.md) **(PREMIUM)**                            | Quickly determine the performance impact of pending code changes.                                                                                                                                         |
| [Code Quality](code_quality.md) **(STARTER)**                                                          | Analyze your source code quality using the [Code Climate](https://codeclimate.com/) analyzer and show the Code Climate report right in the merge request widget area.                                     |
| [Display arbitrary job artifacts](../../../ci/yaml/README.md#artifactsexpose_as)                       | Configure CI pipelines with the `artifacts:expose_as` parameter to directly link to selected [artifacts](../pipelines/job_artifacts.md) in merge requests.                                                |
| [GitLab CI/CD](../../../ci/README.md)                                                                  | Build, test, and deploy your code in a per-branch basis with built-in CI/CD.                                                                                                                              |
| [JUnit test reports](../../../ci/junit_test_reports.md)                                                | Configure your CI jobs to use JUnit test reports, and let GitLab display a report on the merge request so that it’s easier and faster to identify the failure without having to check the entire job log. |
| [Metrics Reports](../../../ci/metrics_reports.md) **(PREMIUM)**                                        | Display the Metrics Report on the merge request so that it's fast and easy to identify changes to important metrics.                                                                                      |
| [Multi-Project pipelines](../../../ci/multi_project_pipelines.md) **(PREMIUM)**                        | When you set up GitLab CI/CD across multiple projects, you can visualize the entire pipeline, including all cross-project interdependencies.                                                              |
| [Pipelines for merge requests](../../../ci/merge_request_pipelines/index.md)                           | Customize a specific pipeline structure for merge requests in order to speed the cycle up by running only important jobs.                                                                                 |
| [Pipeline Graphs](../../../ci/pipelines.md#visualizing-pipelines)                                      | View the status of pipelines within the merge request, including the deployment process.                                                                                                                  |

### Security Reports **(ULTIMATE)**

In addition to the reports listed above, GitLab can do many types of [Security reports](../../application_security/index.md),
generated by scanning and reporting any vulnerabilities found in your project:

| Feature                                                                                 | Description                                                      |
|-----------------------------------------------------------------------------------------|------------------------------------------------------------------|
| [Container Scanning](../../application_security/container_scanning/index.md)            | Analyze your Docker images for known vulnerabilities.            |
| [Dynamic Application Security Testing (DAST)](../../application_security/dast/index.md) | Analyze your running web applications for known vulnerabilities. |
| [Dependency Scanning](../../application_security/dependency_scanning/index.md)          | Analyze your dependencies for known vulnerabilities.             |
| [License Compliance](../../application_security/license_compliance/index.md)            | Manage the licenses of your dependencies.                        |
| [Static Application Security Testing (SAST)](../../application_security/sast/index.md)  | Analyze your source code for known vulnerabilities.              |

## Authorization for merge requests

There are two main ways to have a merge request flow with GitLab:

1. Working with [protected branches](../protected_branches.md) in a single repository
1. Working with forks of an authoritative project

[Learn more about the authorization for merge requests.](authorization_for_merge_requests.md)
