---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Test a new look for epics

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9290) in GitLab 17.2. This feature is an [experiment](../../../policy/experiment-beta-support.md#experiment).

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can enable the feature flags listed in [Feature flags](#feature-flags).
On GitLab.com and GitLab Dedicated, this feature is not available. This feature is available for testing, but not ready for production use.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject
to change or delay and remain at the sole discretion of GitLab Inc.

WARNING:
This project is still in the experimental stage and could result in corruption or loss of production data.
If you would like to enable this feature with no consequences, you are strongly advised to do so in a test environment.

<!-- When epics as work items are made GA, incorporate this content into epics/index.md and redirect
this page there -->

We're working on changing how epics look by migrating them to a unified framework for work items to better
meet the product needs of our Agile Planning offering.

For more information, see [epic 9290](https://gitlab.com/groups/gitlab-org/-/epics/9290) and the
following blog posts:

- [First look: The new Agile planning experience in GitLab](https://about.gitlab.com/blog/2024/06/18/first-look-the-new-agile-planning-experience-in-gitlab/) (June 2024)
- [Unveiling a new epic experience for improved Agile planning](https://about.gitlab.com/blog/2024/07/03/unveiling-a-new-epic-experience-for-improved-agile-planning/) (July 2024)

## Feature flags

To try out this change on GitLab self-managed, enable the following feature flags.
Because this is an experimental feature,
**we strongly advise to enable the feature flags on a new group that does not contain any critical data**.

| Flag                                          | Description                                                                                              | Actor | Status | Milestone |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ----- | ------ | ------ |
| `work_item_epics`                             | Consolidated flag that contains all the changes needed to get epic work items to work for a given group. | Group | **Required** | 17.2 |
| `work_items_rolledup_dates`                   | Calculates the start and due dates in a hierarchy for work items.                                        | Group | **Required** | 17.2 |
| `epic_and_work_item_associations_unification` | Delegates other epic and work item associations.                                                         | Group | **Required** | 17.2 |

## Feedback

If you run into any issue while trying out this change, you can use
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463598) to provide more details.

## Related topics

- [Work items development](../../../development/work_items.md)
