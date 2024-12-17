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

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9290) in GitLab 17.2 with [several feature flags](#enable-and-disable-the-new-look-for-epics). Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md#experiment).
> - Listing epics using the [GraphQL API](../../../api/graphql/reference/index.md) [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12852) in GitLab 17.4.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/470685) in GitLab 17.6.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

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

## Enable and disable the new look for epics

To try out this change on GitLab self-managed, run the following Rake task.
The task performs a database verification to ensure data consistency and might take a few minutes.
If the consistency check passes, the Rake task enables the `work_item_epics` feature flag.

If the check fails, the feature flag is not enabled. Inconsistencies are logged in the `epic_work_item_sync.log` file.
Failed background migrations or invalid imports can cause data inconsistencies. These inconsistencies will be resolved when work item epics become generally available.

**To enable:**

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:work_items:epics:enable

# installation from source
bundle exec rake gitlab:work_items:epics:enable RAILS_ENV=production
```

**To disable:**

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:work_items:epics:disable

# installation from source
bundle exec rake gitlab:work_items:epics:disable RAILS_ENV=production
```

## Feedback

If you run into any issues while trying out this change, you can use
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/463598) to provide more details.

## Related topics

- [Work items development](../../../development/work_items.md)
