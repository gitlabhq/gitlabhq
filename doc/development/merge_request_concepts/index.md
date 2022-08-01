---
type: reference, dev
stage: Create
group: Code Review
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Merge request concepts

NOTE:
The documentation below is the single source of truth for the merge request terminology and functionality.

The merge request is made up of several different key components and ideas that encompass the overall merge request experience. These concepts sometimes have competing and confusing terminology or overlap with other concepts. The concepts this will cover are:

1. Merge widget
1. Report widgets
1. Merge checks
1. Approval rules

When developing new merge request widgets, read the
[merge request widget extension framework](../new_fe_guide/modules/widget_extensions.md)
documentation. All new widgets should use this framework, and older widgets should
be ported to use it.

## Merge widget

The merge widget is the component of the merge request where the `merge` button exists:

![merge widget](../img/merge_widget_v14_7.png)

This area of the merge request is where all of the options and commit messages are defined prior to merging. It also contains information about what is in the merge request, what issues may be closed, and other important information to the merging process.

## Report widgets

Reports are widgets within the merge request that report information about changes within the merge request. These widgets provide information to better help the author understand the changes and further improvements to the proposed changes.

[Design Documentation](https://design.gitlab.com/regions/merge-request-reports)

![merge request reports](../img/merge_request_reports_v14_7.png)

## Merge checks

Merge checks are statuses that can either pass or fail and conditionally control the availability of the merge button being available within a merge request. The key distinguishing factor in a merge check is that users **do not** interact with the merge checks inside of the merge request, but are able to influence whether or not the check passes or fails. Results from the check are processed as true/false to determine whether or not a merge request can be merged. Examples include:

- Merge conflicts.
- Pipeline success.
- Threads resolution.
- [External status checks](../../user/project/merge_requests/status_checks.md).
- Required approvals.

When all of the required merge checks are satisfied a merge request becomes mergeable.

## Approvals

Approval rules specify users that are required to or can optionally approve a merge request based on some kind of organizational policy. When approvals are required, they effectively become a required merge check. The key differentiator between merge checks and approval rules is that users **do** interact with approval rules, by deciding to approve the merge request.

Additionally, approval settings provide configuration options to define how those approval rules are applied in a merge request. They can set limitations, add requirements, or modify approvals.

Examples of approval rules and settings include:

1. [merge request approval rules](../../user/project/merge_requests/approvals/rules.md)
1. [code owner approvals](../../user/project/code_owners.md)
1. [security approvals](../../user/application_security/index.md#security-approvals-in-merge-requests)
1. [prevent editing approval rules](../../user/project/merge_requests/approvals/settings.md#prevent-editing-approval-rules-in-merge-requests)
1. [remove all approvals when commits are added](../../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)
