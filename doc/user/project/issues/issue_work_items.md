---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test a new look for issues
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9584) in GitLab 17.5 [with a flag](../../../administration/feature_flags/_index.md) named `work_items_view_preference`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).
- Feature flag named `work_items_view_preference` enabled on GitLab.com in GitLab 17.9 for a subset of users.
- Feature flag named `work_items_view_preference` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184496) on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in 17.10.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/482931) in GitLab 17.11.
- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/482931) to feature flag named `work_item_view_for_issues` in GitLab 18.1. Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated. Feature flag `work_items_view_preference` removed.
- Additional filters on the Issues page in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198544) in GitLab 18.4. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204139).
- Additional filters on the Issues page in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202089) in GitLab 18.5. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205308).

{{< /history >}}

<!-- Incorporate this content into issues/index.md or managing_issues.md and redirect this page there -->

We have changed how issues look by migrating them to a unified framework for work items to better
meet the product needs of our Agile Planning offering.

These changes include a new drawer view of issues opened from the issue list, issue board, or child or linked items, a new creation workflow for issues and incidents, and a new view for issues.

For more information, see [epic 9584](https://gitlab.com/groups/gitlab-org/-/epics/9584) and the
blog post
[First look: The new Agile planning experience in GitLab](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/) (June 2024).

## Feedback

Find a bug or have a request? Leave feedback in [issue 523713](https://gitlab.com/gitlab-org/gitlab/-/issues/523713).

## New features

The new issues experience includes these improvements:

- **Drawer view**: When you open an issue from the issue list, the issue opens in a
  drawer without leaving the current page.
  The drawer provides a complete view of the issue.

  To view the full page instead, either:
  1. Select **View in full page** at the top of the drawer.
  1. Open the link in a new tab.

  To always open issues in the full page view on the Epics page, in the upper-right corner, select **Display options** ({{< icon name="preferences" >}}) and turn off the **Open items in side panel** toggle.
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
- **Issue list on projects and groups**: The project and group issue list is powered by work items. It adds new capabilities like:
  - Filter tasks by their parent issue, in addition to filtering issues by epic.
  - Filter by custom statuses.
  - Configure display preferences for metadata such as assignee, labels, milestone, dates, health status, comments, iteration, blocked or blocking status, and popularity.
  - Bulk edit state and parent of any work item type.

## Work item Markdown reference

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352861) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `extensible_reference_filters`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052) in GitLab 18.2. Feature flag `extensible_reference_filters` removed.

{{< /history >}}

You can reference work items in GitLab Flavored Markdown fields with `[work_item:123]`.
For more information, see [GitLab-specific references](../../markdown.md#gitlab-specific-references).
