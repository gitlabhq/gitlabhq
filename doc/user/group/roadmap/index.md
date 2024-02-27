---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Roadmap

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/198062) from GitLab Ultimate to GitLab Premium in 12.9.
> - In [GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/5164) and later, the epic bars show epics' title, progress, and completed weight percentage.
> - Milestones appear in roadmaps in [GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/issues/6802), and later.
> - Feature flag for milestones visible in roadmaps [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29641) in GitLab 13.0.
> - In [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/214375) and later, the Roadmap also shows milestones in projects in a group.
> - In [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/212494) and later, milestone bars can be collapsed and expanded.

Epics and milestones in a group containing a start date or due date can be visualized in a form
of a timeline (that is, a Gantt chart). The Roadmap page shows the epics and milestones in a
group, one of its subgroups, or a project in one of the groups.

On the epic bars, you can see each epic's title, progress, and completed weight percentage.
When you hover over an epic bar, a popover appears with the epic's title, start date, due date, and
weight completed.

You can expand epics that contain child epics to show their child epics in the roadmap.
You can select the chevron (**{chevron-down}**) next to the epic title to expand and collapse the
child epics.

On top of the milestone bars, you can see their title. When you point to a
milestone bar or title, a popover appears with its title, start date, and due
date. You can also select the chevron (**{chevron-down}**) next to the **Milestones**
heading to toggle the list of the milestone bars.

![roadmap view](img/roadmap_view_v14_3.png)

## Sort and filter the Roadmap

> - Filtering by milestone [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218621) in GitLab 13.7 [with a flag](../../../administration/feature_flags.md) named `roadmap_daterange_filter`. Enabled by default.
> - Filtering by epic confidentiality [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218624) in GitLab 13.9.
> - Filtering by epic [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218623) in GitLab 13.11.
> - Filtering by milestone [feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323917) in GitLab 14.5.
> - Filtering by group was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385191) in GitLab 15.9.

NOTE:
Filtering roadmaps by milestone might not be available to you. Be sure to review this section's history for details.

When you want to explore a roadmap, there are several ways to make it easier by sorting epics or
filtering them by what's important for you.

You can sort epics in the Roadmap view by:

- Start date
- Due date

Each option contains a button that toggles the sort order between **ascending**
and **descending**. The sort option and order persist when browsing Epics, including
the [epics list view](../epics/index.md).

You can also filter epics in the Roadmap view by the epics':

- Author
- Label
- Milestone
- [Confidentiality](../epics/manage_epics.md#make-an-epic-confidential)
- Epic
- Your Reaction
- Groups

![roadmap date range in weeks](img/roadmap_filters_v13_11.png)

You can also [visualize roadmaps inside of an epic](../epics/index.md#roadmap-in-epics).

### Roadmap settings

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345158) in GitLab 14.8 [with a flag](../../../administration/feature_flags.md) named `roadmap_settings`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350830) in GitLab 14.9. Feature flag `roadmap_settings`removed.
> - Labels visible on roadmaps [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385231) in GitLab 15.9.

When you enable the roadmap settings sidebar, you can use it to refine epics shown in the roadmap.

You can configure the following:

- Select date range.
- Turn milestones on or off, and select whether to show all, group, subgroup, or
  project milestones.
- Show all, open, or closed epics.
- Turn progress tracking for child issues on or off and select whether
  to use issue weights or counts.
- Turn labels on or off.

The progress tracking setting isn't saved in user preferences, but is saved or
shared using URL parameters.

## Timeline duration

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/198062) from GitLab Ultimate to GitLab Premium in 12.9.

### Date range presets

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/204994) in GitLab 14.3 [with a flag](../../../administration/feature_flags.md) named `roadmap_daterange_filter`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/323917) in GitLab 14.3.
> - Generally available in GitLab 14.5. [Feature flag `roadmap_daterange_filter`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72419) removed.

Roadmap provides these date range options, each with a predetermined timeline duration:

- **This quarter**: Includes the weeks present in the current quarter.
- **This year**: Includes the weeks or months present in the current year.
- **Within 3 years**: Includes the weeks, months, or quarters present both in
  the previous 18 months and the upcoming 18 months (three years in total).

### Layout presets

Depending on selected [date range preset](#date-range-presets), Roadmap supports
these layout presets:

- **Quarters**: Available only when the **Within 3 years** date range is selected.
- **Months**: Available when either **This year** or **Within 3 years** date range is selected.
- **Weeks** (default): Available for all the date range presets.

### Quarters

![roadmap date range in quarters](img/roadmap_timeline_quarters.png)

In the **Quarters** preset, roadmap shows epics and milestones which have start or due dates
**falling within** currently selected date range preset,
where **today**
is shown by the vertical red line in the timeline. The sub-headers underneath the quarter name on
the timeline header represent the month of the quarter.

### Months

![roadmap date range in months](img/roadmap_timeline_months.png)

In the **Months** preset, roadmap shows epics and milestones which have start or
due dates **falling within** or **going through** currently selected date range
preset, where **today** is shown by the vertical red line in the timeline. The
sub-headers underneath the month name on the timeline header represent the date
on the start day (Sunday) of the week. This preset is selected by default.

### Weeks

![roadmap date range in weeks](img/roadmap_timeline_weeks.png)

In the **Weeks** preset, roadmap shows epics and milestones which have start or due dates **falling
within** or **going through** currently selected date range preset, where **today**
is shown by the vertical red line in the timeline. The sub-headers underneath the week name on
the timeline header represent the days of the week.

## Roadmap timeline bar

The timeline bar indicates the approximate position of an epic or milestone based on its start and
due dates.

## Blocked epics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33587) in GitLab 15.5: View blocking epics when hovering over the "blocked" icon.

If an epic is [blocked by another epic](../epics/linked_epics.md#blocking-epics), an icon appears next to its title to indicate its blocked status.

When you hover over the blocked icon (**{issue-block}**), a detailed information popover is displayed.

![Blocked epics](img/roadmap_blocked_icon_v15_5.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
