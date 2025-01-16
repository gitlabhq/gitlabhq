---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Test a new look for issues

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9584) in GitLab 17.5 [with a flag](../../../administration/feature_flags.md) named `work_items_view_preference`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).

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

## Troubleshooting

If you're participating in a pilot of the new issues experience, you can disable the new view.
To do so, in the top right of an issue, select **New issue view**.

## Feedback

### Customers

Customers participating in the pilot program, or who have voluntarily enabled the new experience, can leave feedback in [issue 513408](https://gitlab.com/gitlab-org/gitlab/-/issues/513408).

### Internal users

GitLab team members using the new experience should leave feedback in confidential issue
`https://gitlab.com/gitlab-org/gitlab/-/issues/512715`.

## Related topics

- [Work items development](../../../development/work_items.md)
- [Test a new look for epics](../../group/epics/epic_work_items.md)
