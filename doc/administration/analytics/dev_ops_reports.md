---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DevOps Reports

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

DevOps Reports give you an overview of your entire instance's adoption of
[DevOps](https://about.gitlab.com/topics/devops/)
from planning to monitoring.

## DevOps Score

NOTE:
To see the DevOps score, you must activate your GitLab instance's [Service Ping](../settings/usage_statistics.md#service-ping). DevOps Score is a comparative tool, so your score data must be centrally processed by GitLab Inc. first.

You can use the DevOps score to compare your DevOps status to other organizations.

The DevOps Score tab displays usage of major GitLab features on your instance over
the last 30 days, averaged over the number of billable users in that time period.
You can also see the Leader usage score, calculated from top-performing instances based on
[Service Ping data](../settings/usage_statistics.md#service-ping) that GitLab has collected.
Your score is compared to the lead score of each feature and then expressed
as a percentage at the bottom of said feature. Your overall **DevOps Score** is an average of your
feature scores.

Service Ping data is aggregated on GitLab servers for analysis. Your usage
information is **not sent** to any other GitLab instances.
If you have just started using GitLab, it might take a few weeks for data to be collected before this
feature is available.

## DevOps Adoption

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed

DevOps Adoption shows feature adoption for development, security, and operations.

| Category    | Feature |
|-------------|---------|
| Development | Approvals<br>Code owners<br>Issues<br>Merge requests |
| Security    | DAST<br>Dependency Scanning<br>Fuzz Testing<br>SAST |
| Operations  | Deploys<br>Pipelines<br>Runners |

You can use DevOps Adoption to:

- Identify groups that are lagging in their adoption of GitLab features,
  so you can guide them on their DevOps journey.
- Identify groups that have adopted certain GitLab features, and use them as an example
  for other groups to adopt those features.
- Evaluate if you are getting the expected return on investment from GitLab.

## View DevOps Reports

To view DevOps Reports:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Analytics > DevOps Reports**.

The **Overview tab** displays the number of features adopted in each category by the groups that use DevOps Reports.

The **Adoption by group** table lists the features used by each group.

## Add or remove a group

To add a group to or remove a group from DevOps Reports:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Analytics > DevOps Reports**.
1. From the **Add or remove groups** dropdown list, select the group you want to add or remove.
