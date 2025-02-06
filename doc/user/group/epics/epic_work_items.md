---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test a new look for epics
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9290) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `work_item_epics`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md#beta).
> - Listing epics using the [GraphQL API](../../../api/graphql/reference/_index.md) [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12852) in GitLab 17.4.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/470685) in GitLab 17.6.
> - [Enabled by default on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) in GitLab 17.7.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

<!-- When epics as work items are generally available and `work_item_epics` flag is removed,
incorporate this content into epics/index.md and redirect this page there -->

We have changed how epics look by migrating them to a unified framework for work items to better
meet the product needs of our Agile Planning offering.

For more information, see [epic 9290](https://gitlab.com/groups/gitlab-org/-/epics/9290) and the
following blog posts:

- [First look: The new Agile planning experience in GitLab](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/) (June 2024)
- [Unveiling a new epic experience for improved Agile planning](https://about.gitlab.com/blog/2024/07/03/unveiling-a-new-epic-experience-for-improved-agile-planning/) (July 2024)

## Troubleshooting

If you run into any issues while navigating your data in the new experience, there are a couple
of ways you can try to resolve it.

### Access the old experience

You can temporarily load the old experience by editing URL to include `force_legacy_view=true` parameter,
for example, `https://gitlab.com/groups/gitlab-org/-/epics/9290?force_legacy_view=true`. Use this parameter to do any comparison
between old and new experience to provide details while opening support request.

### Disable the new experience

DETAILS:
**Offering:** GitLab Self-Managed

We don't recommend disabling this change, because we'd like your feedback on what you don't like about it.
If you have to disable the new experience to unblock your workflow, disable the `work_item_epics`
[feature flag](../../../administration/feature_flags.md#how-to-enable-and-disable-features-behind-flags).

## Feedback

If you run into any issues while trying out this change, you can use
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/494462) to provide more details.

## Related topics

- [Work items development](../../../development/work_items.md)
