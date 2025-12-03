---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Issues
description: Tasks, bug reports, feature requests, and tracking.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Issues help you collaborate with your team to plan, track, and deliver work in GitLab.
Issues:

- Track feature proposals, tasks, support requests, and bug reports.
- Organize and prioritize work with assignees, due dates, and health status.
- Facilitate team discussion and decision-making through comments and threaded discussions.
- Support custom workflows through templates, labels, epics, and boards.
- Integrate with external tools like Zoom, Jira, and email services.

For more information about issues, see the GitLab blog post:
[Always start a discussion with an issue](https://about.gitlab.com/blog/2016/03/03/start-with-an-issue/).

Issues are always associated with a specific project. If you have multiple
projects in a group, you can view all of the projects' issues at once.

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=Mt1EzlKToig">Issues - Setting up your Organization with GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/Mt1EzlKToig" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2023-10-30 -->

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
To learn how the GitLab Strategic Marketing department uses GitLab issues with [labels](../labels.md) and
[issue boards](../issue_board.md), see the video on
[Managing Commitments with Issues](https://www.youtube.com/watch?v=cuIHNintg1o&t=3).
<!-- Video published on 2020-04-10 -->

## Issues as work items

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9584) in GitLab 17.5 [with a flag](../../../administration/feature_flags/_index.md) named `work_items_view_preference`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).
- Feature flag named `work_items_view_preference` enabled on GitLab.com in GitLab 17.9 for a subset of users.
- Feature flag named `work_items_view_preference` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184496) on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in 17.10.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/482931) in GitLab 17.11.
- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/482931) to feature flag named `work_item_view_for_issues` in GitLab 18.1. Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated. Feature flag `work_items_view_preference` removed.
- Additional filters on the Issues page in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198544) in GitLab 18.4. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204139).
- Additional filters on the Issues page in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202089) in GitLab 18.5. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205308).
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/520791) in GitLab 18.7. Feature flag `work_item_view_for_issues` removed.

{{< /history >}}

We have changed how issues look by migrating them to a unified framework for work items to better
meet the product needs of our Agile Planning offering.

For more information, see [epic 9290](https://gitlab.com/groups/gitlab-org/-/epics/9290) and the blog post
[First look: The new Agile planning experience in GitLab](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/)
(June 2024).

If you run into any issues while trying out this change, you can use the
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523713) to provide more details.

### Work item Markdown reference

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352861) in GitLab 18.1 [with a flag](../../../administration/feature_flags/_index.md) named `extensible_reference_filters`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052) in GitLab 18.2. Feature flag `extensible_reference_filters` removed.

{{< /history >}}

You can reference work items in GitLab Flavored Markdown fields with `[work_item:123]`.
For more information, see [GitLab-specific references](../../markdown.md#gitlab-specific-references).

## Related topics

- [Create issues](create_issues.md)
- [Create an issue from a template](../description_templates.md#use-the-templates)
- [Edit issues](managing_issues.md#edit-an-issue)
- [Move issues](managing_issues.md#move-an-issue)
- [Close issues](managing_issues.md#close-an-issue)
- [Delete issues](managing_issues.md#delete-an-issue)
- [Promote issues](managing_issues.md#promote-an-issue-to-an-epic)
- [Set a due date](due_dates.md)
- [Import issues](csv_import.md)
- [Export issues](csv_export.md)
- [Upload designs to issues](design_management.md)
- [Linked issues](related_issues.md)
- [Similar issues](managing_issues.md#similar-issues)
- [Health status](managing_issues.md#health-status)
- [Cross-link issues](crosslinking_issues.md)
- [Sort issue lists](sorting_issue_lists.md)
- [Search for issues](managing_issues.md#filter-the-list-of-issues)
- [Epics](../../group/epics/_index.md)
- [Issue boards](../issue_board.md)
- [Issues API](../../../api/issues.md)
- [Configure an external issue tracker](../../../integration/external-issue-tracker.md)
- [Tasks](../../tasks.md)
- [View count and weight of tasks in an issue](../../tasks.md#view-count-and-weight-of-tasks-in-the-parent-issue)
- [View progress of an issue with child tasks](../../tasks.md#view-progress-of-the-parent-issue)
- [External participants](../service_desk/external_participants.md)
