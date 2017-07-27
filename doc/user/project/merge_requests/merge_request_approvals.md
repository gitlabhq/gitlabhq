# Merge request approvals

> Introduced in [GitLab Enterprise Edition 7.12](https://about.gitlab.com/2015/06/22/gitlab-7-12-released/#merge-request-approvers-ee-only), available in [GitLab Enterprise Edition Starter](https://about.gitlab.com/gitlab-ee/).

## Overview

If you want to make sure every merge request is approved by one or more
people, you can enforce this workflow by using merge request approvals.

Merge request approvals allow you to set the number of necessary approvals
and predefine a list of approvers that will need to approve every
merge request in a project.

## Use cases

There are numerous use cases for merge request approvals. For instance,
let's consider you're a backend developer working in a team:

1. You submit changes to your project via merge request
1. You gather feedback from your team members in the merge request
1. You build, test, and deploy your app with [GitLab CI/CD](../../../ci/README.md)
1. Once everything is ready to ship, you add your manager and the project manager as approvers to that merge request
1. Your approvers get a notification and review your modifications
1. You need to address your managers' comments, so you push again to your branch
1. Once you pushed, that merge request will need another round of approvals
1. You ask your managers again for their approval
1. They approve and merge

This example workflow prevents your implementations from being merged before getting approvals from both managers.

## Configuring Approvals

You can configure the approvals in the project settings, under merge requests.
To enable it, turn on **Activate merge request approvals** and search for the
users you want to be approvers.

![Merge Request Approvals in Project Settings](img/approvals_settings.png)

### Approvals Required

This sets the amount of approvals required before being able to merge a merge request.

The number of approvers can be higher than the required approvals.

### Can override approvers and approvals required per merge request

> Introduced in GitLab Enterprise Edition 9.4.

When this setting is enabled, the approvers for a project can be overridden for
a merge request. When editing a merge request you can add or remove approvers,
and increase the number of required approvers.

### Reset approvals on push

With this setting turned on, approvals are reset when a new push
is done to the merge request branch.

Turn **Reset approvals on push** off if you want approvals to persist,
independent of changes to the merge request.

Approvals do not get reset when rebasing a merge request from the UI.

If one of the approvers pushes a commit to the branch that is tied to the
merge request, they automatically get excluded from the approvers list.

### Approvers

At the approvers area you can select the default set of users that need to
approve a merge request.

Depending on the number of required approvals and the number of approvers set,
there are different cases:

- If there are more approvers than required approvals, any subset of these users
  can approve the merge request.
- If there are less approvers than required approvals, all the set approvers plus
  any other user(s) need to approve the merge request before being able to merge it.
- If the approvers are equal to the amount of required approvals, all the
  approvers are required to approve the merge request.

Note that approvers and the number of required approvals can be changed while
creating or editing a merge request.

When someone is marked as a required approver for a merge request, an email is
sent to them and a todo is added to their list of todos.

### Selecting individual approvers

GitLab restricts the users that can be selected to be individual approvers. Only these can be selected and appear in the search box:
- Members of the current project
- Members of the parent group of the current project
- Members of a group that have access to the current project [via a share](../../../workflow/share_projects_with_other_groups.md)

### Selecting group approvers

> [Introduced][ee-743] in GitLab Enterprise Edition 8.13.

You can also define one or more groups that can be assigned as approvers. It
works the same way like regular approvers do, the only difference is that you
assign several users with one action. One possible scenario would be to to assign
a group of approvers at the project level and change them later when creating
or editing the merge request.

## Removing approval

A designated approver can remove their approval at any time. If, when an approver
removes their approval, the number of approvals given falls below the number of
required approvals, the merge request cannot be accepted.

If, on the other hand, an approver removes their approval but the number of approvals
given stays at or above the number of required approvals, the merge request can still be
accepted.

## Using approvals

After configuring approvals, you will be able to change the default set of
approvers and the amount of required approvals before creating the merge request.
The amount of required approvals, if changed, must be greater than the default
set at the project level. This ensures that you're not forced to adjust settings
when someone is unavailable for approval, yet the process is still enforced.

If the approvers are changed via the project's settings after a merge request
is created, the merge request retains the previous approvers, but you can always
change them by editing the merge request.

The author of a merge request cannot be set as an approver for that merge
request.

To approve a merge request, simply press the **Approve merge request** button.

![Merge request approval](img/approvals_mr.png)

Once you approve, the button will disappear and the number of approvers
will be decreased by one.

![Merge request approval](img/approvals_mr_approved.png)

[ee-743]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/743

To remove approval, just press the **Remove your approval** button

![Merge request remove approval](img/remove_approval_mr.png)
