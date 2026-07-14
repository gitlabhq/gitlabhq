---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Snowflake
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/451328) for audit events in GitLab 17.1.

{{< /history >}}

The Snowflake [GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector) pulls data into [Snowflake](https://www.snowflake.com/en/).

In Snowflake you can then view, combine, manipulate, and report on all of the data. The GitLab Data Connector is based on [GitLab REST APIs](../api/rest/_index.md) and
requires both Snowflake and GitLab configuration.

## Prerequisites

1. If you do not have a GitLab personal access token:
   1. Sign in to GitLab.
   1. Follow steps outlined to [create a personal access token](../user/profile/personal_access_tokens.md#create-a-personal-access-token).
1. Create a [external access integration](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access) in Snowflake. For more information,
   see [setup documentation](https://gitlab.com/gitlab-org/software-supply-chain-security/compliance/engineering/snowflake-connector#setup) in the `snowflake-connector` project.
1. Create a [warehouse](https://docs.snowflake.com/en/user-guide/warehouses-tasks#creating-a-warehouse) in Snowflake.

## Configure the GitLab Data Connector

1. Sign in to Snowflake.
1. Select **Data Products** > **Marketplace**.
1. Search for **GitLab Data Connector**.
1. Select **Data Products** > **Apps**.
1. Select **GitLab Data Connector**.
1. Select a [warehouse](https://docs.snowflake.com/en/user-guide/warehouses) where the GitLab Data Connector runs.
1. Select **Start Configuration**.
1. Select **Grant privileges**.
1. Enter a destination warehouse and schema. These can be any warehouse and schema that you want.
1. Select **Configure**.
1. Enter an External access integration.
1. Enter the path where the GitLab personal access token secret is stored.
1. Enter the domain for your GitLab instance. For example, `gitlab.com`.
1. Select **Connect**.
1. Enter a group name. For example, `my-group`.
1. Select **Finalize configurator**.
1. Select **Configure**.

## Enable projects and groups

After configuring the GitLab Data Connector, you must specify which projects
or groups have their audit events ingested into Snowflake.
If you do not add at least one project or group, no data is ingested.

### Enable projects

To add projects whose audit events you want to ingest:

1. Sign in to Snowflake.
1. Select **Data Products** > **Apps**.
1. Select **GitLab Data Connector**.
1. Select the **Enabled Projects** tab.
1. Enter the path of the project you want to enable. For example, `my-group/my-project`.
1. Select **Add**.
1. Repeat for each additional project.

### Enable groups

To add groups whose audit events you want to ingest:

1. Sign in to Snowflake.
1. Select **Data Products** > **Apps**.
1. Select **GitLab Data Connector**.
1. Select the **Enabled Groups** tab.
1. Enter the path of the group you want to enable. For example, `my-group`.
1. Select **Add**.
1. Repeat for each additional group.

## View data in Snowflake

1. Sign in to Snowflake.
1. Select **Data** > **Databases**.
1. Select the warehouse previously configured.

## Troubleshooting

### No data appearing in Snowflake

If no data appears in Snowflake, check the following:

- You have not added at least one project or group in the **Enabled Projects** or **Enabled Groups** tab.
  For more information, see [Enable projects and groups](#enable-projects-and-groups).
- The GitLab personal access token does not have the required scopes to read audit events.
- The Snowflake warehouse configured for the GitLab Data Connector is suspended.
