---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test a new look for issues
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9584) in GitLab 17.5 [with a flag](../../../administration/feature_flags.md) named `work_items_view_preference`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).
> - Enabled on GitLab.com in GitLab 17.9 for a subset of users.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

<!-- When issues as work items are generally available and `work_items_view_preference` flag is removed,
incorporate this content into issues/index.md or managing_issues.md and redirect this page there -->

We have changed how issues look by migrating them to a unified framework for work items to better
meet the product needs of our Agile Planning offering.

These changes include a new drawer view of issues opened from the issue list or issue board, a new creation workflow for issues and incidents, and a new view for issues.

For more information, see [epic 9584](https://gitlab.com/groups/gitlab-org/-/epics/9584) and the
blog post
[First look: The new Agile planning experience in GitLab](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/) (June 2024).

## New features

The new issues experience includes these improvements:

- **Contextual view**: When you open an issue from the issue list or board, the issue opens in a
  drawer without leaving the current page.
  The drawer provides a complete view of the issue.
  To view the full page instead, either:
  1. Select **View in full page** at the top of the drawer.
  1. Open the link in a new tab.
- **Issue controls**: All issue controls, including confidentiality settings, are now in the top actions menu.
  This menu stays visible as you scroll through the page.
- **Redesigned sidebar**: The sidebar is now embedded in the page, similar to merge requests and epics.
  On smaller screens, the sidebar content appears below the description.
- **Parent hierarchy**: Above the title, you can view the entire hierarchy this item belongs to.
  The sidebar also displays the parent work item (previously called "Epic").
- **Change type**: You can change between different types of items:
  1. From the top actions menu, select **Change type**.
  1. Select the new type: Issue, Task, Incident, or Epic.
     When you change an issue to an epic, the epic is created in the parent group because epics can
     only exist in groups.
- **Development**: Merge requests, branches, and feature flags related to this item are shown in a single list.

## Toggle the new experience

When you view an issue list or issue detail page, you can manage the new experience:

1. In the upper-right corner, next to the Duo Chat button, look for the **New issue look** badge.
1. Select the badge to toggle the experience on or off.

## Known issues

See the [full list of known issues](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&or%5Blabel_name%5D%5B%5D=work%20items%3A%3Aissues-ga_immediate-follow&or%5Blabel_name%5D%5B%5D=work%20items%3A%3Aga-issues)
planned to be addressed before general availability.

## Feedback

### Customers

Customers participating in the pilot program, or who have voluntarily enabled the new experience, can leave feedback in [issue 513408](https://gitlab.com/gitlab-org/gitlab/-/issues/513408).

### Internal users

GitLab team members using the new experience should leave feedback in confidential issue
`https://gitlab.com/gitlab-org/gitlab/-/issues/512715`.

## Related topics

- [Work items development](../../../development/work_items.md)
- [Test a new look for epics](../../group/epics/epic_work_items.md)
