---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Iterations **(STARTER)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214713) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.1.
> - It was deployed behind a feature flag, disabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/221047) on GitLab 13.2.
> - It's enabled on GitLab.com.
> - It's able to be enabled or disabled per-group.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#disable-iterations). **(STARTER ONLY)**

Iterations are a way to track issues over a period of time. This allows teams
to track velocity and volatility metrics. Iterations can be used with [milestones](../../project/milestones/index.md)
for tracking over different time periods.

For example, you can use:

- Milestones for Program Increments, which span 8-12 weeks.
- Iterations for Sprints, which span 2 weeks.

In GitLab, iterations are similar to milestones, with a few differences:

- Iterations are only available to groups.
- A group can only have one active iteration at a time.
- Iterations require both a start and an end date.
- Iteration date ranges cannot overlap.

## View the iterations list

To view the iterations list, in a group, go to **{issues}** **Issues > Iterations**.
From there you can create a new iteration or click an iteration to get a more detailed view.

## Create an iteration

NOTE: **Note:**
You need Developer [permissions](../../permissions.md) or higher to create an iteration.

To create an iteration:

1. In a group, go to **{issues}** **Issues > Iterations**.
1. Click **New iteration**.
1. Enter the title, a description (optional), a start date, and a due date.
1. Click **Create iteration**. The iteration details page opens.

## Edit an iteration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218277) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.2.

NOTE: **Note:**
You need Developer [permissions](../../permissions.md) or higher to edit an iteration.

To edit an iteration, click the three-dot menu (**{ellipsis_v}**) > **Edit iteration**.

## Add an issue to an iteration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216158) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.2.

To learn how to add an issue to an iteration, see the steps in
[Managing issues](../../project/issues/managing_issues.md#add-an-issue-to-an-iteration).

## View an iteration report

> Viewing iteration reports in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222763) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.5.

You can track the progress of an iteration by reviewing iteration reports.
An iteration report displays a list of all the issues assigned to an iteration and their status.

To view an iteration report, go to the iterations list page and click an iteration's title.

### Iteration burndown and burnup charts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222750) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/269972) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.7.

The iteration report includes [burndown and burnup charts](../../project/milestones/burndown_and_burnup_charts.md),
similar to how they appear when viewing a [milestone](../../project/milestones/index.md).

Burndown charts help track completion progress of total scope, and burnup charts track the daily
total count and weight of issues added to and completed in a given timebox.

## Disable iterations **(STARTER ONLY)**

GitLab Iterations feature is deployed with a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can disable it for your instance. `:group_iterations` can be enabled or disabled per-group.

To enable it:

```ruby
# Instance-wide
Feature.enable(:group_iterations)
# or by group
Feature.enable(:group_iterations, Group.find(<group ID>))
```

To disable it:

```ruby
# Instance-wide
Feature.disable(:group_iterations)
# or by group
Feature.disable(:group_iterations, Group.find(<group ID>))
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
