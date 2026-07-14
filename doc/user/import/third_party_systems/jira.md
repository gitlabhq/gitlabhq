---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: Migrate from Jira
description: Options for migrating from Jira
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If you use Jira, you can either:

- Start fresh in GitLab without migrating from Jira. You can then focus on setting up your processes and workflows to
  maximize the advantages of using GitLab.
- Migrate from Jira to GitLab by using one of several options.

| Migration option             | Description |
|:-----------------------------|:------------|
| GitLab Professional Services | Have [GitLab Professional Services](https://about.gitlab.com/services/) perform the migration for you. |
| `Jira2Lab`                   | Use [`Jira2Lab`](https://about.gitlab.com/blog/seamlessly-migrate-from-jira-to-gitlab-with-jira2lab-at-scale/), the GitLab Professional Services fork of `jira2gitlab`. |
| Third-party script           | For example, use [`jira2gitlab`](https://github.com/swingbit/jira2gitlab) for the migration. |
| Jira importer                | [Use the Jira importer](#use-the-jira-importer) that is built into GitLab. |
| CSV file import              | [Use a CSV file](#use-a-csv-file) to move data from Jira to GitLab. |
| Your own script              | [Write your own script](#write-your-own-script) that uses the GitLab REST or GraphQL API. |
| Third-party service          | Use a third-party service that keeps GitLab and Jira synchronized, such as those from [Unito](https://marketplace.atlassian.com/apps/1218054/gitlab-2-way-integration-for-jira) and [Getint](https://marketplace.atlassian.com/apps/1223999/gitlab-integration-for-jira-two-way-sync-forge). |

## Use the Jira importer

Using the Jira importer, you can import your Jira issues to GitLab. Issues from multiple Jira projects can be imported into
a GitLab project. GitLab imports the issue's title, description, and labels directly. You can also map Jira users to
GitLab project members when preparing for the import.

Other Jira issue metadata that is not formally mapped to GitLab issue fields is
imported into the GitLab issue's description as plain text.

Text in Jira issues is not parsed to GitLab Flavored Markdown, which can result in broken text formatting.
For more information, see [issue 379104](https://gitlab.com/gitlab-org/gitlab/-/issues/379104).

[Epic 2738](https://gitlab.com/groups/gitlab-org/-/epics/2738) proposes the addition of issue assignees,
comments, and other improvements to the GitLab Jira importer.

### Prerequisites

- Read access on Jira issues and the Maintainer or Owner role for the GitLab project that you want to
  import into.
- Configure the GitLab [Jira issue integration](../../../integration/jira/_index.md).

### Import Jira issues

Importing Jira issues is done as an asynchronous background job, which can result in delays based on:

- Import queues load.
- System load.
- Other factors.

Importing large projects can take several minutes depending on the size of the import.

To import Jira issues to a GitLab project:

1. On the {{< icon name="work-items" >}} **Work items** page, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Import from Jira**.

1. Select the **Import from** dropdown list and select the Jira project that you wish to import issues from.

   In the **Jira-GitLab user mapping template** section, the table shows to which GitLab users your Jira
   users are mapped.
   When the form appears, the dropdown list defaults to the user conducting the import.

1. To change any of the mappings, select the dropdown list in the **GitLab username** column and
   select the user you want to map to each Jira user.

   The dropdown list may not show all the users, so use the search bar to find a specific
   user in this GitLab project.

1. Select **Continue**. You're presented with a confirmation that the import has started.

   While the import is running in the background, you can go
   to the **Work items** page to see the new issues (work items of type Issue) appearing in the list.

1. To check the status of your import, go to the Jira import page again.

## Use a CSV file

To import your Jira issue data from a CSV file into your GitLab project:

1. Export your Jira data:
   1. Log in to your Jira instance and go to the project you want to migrate.
   1. Export the project data as a CSV file.
   1. Edit your CSV file to match the [column names required for the GitLab CSV importer](../../project/issues/csv_import.md).
      - Only `title`, `description`, `due_date`, and `milestone` are imported.
      - You can add [quick actions](../../project/quick_actions.md) to the description field to set other issue metadata automatically during the import process.
1. Create a new GitLab group and project:
   1. Sign in to your GitLab account and [create a group](../../group/_index.md#create-a-group) to host your migrated projects.
   1. In the new group, [create a new project](../../project/_index.md#create-a-blank-project) to hold the migrated Jira issues.
1. Import the Jira data into GitLab:
   1. In your new GitLab project, in the left sidebar, select **Plan** > **Work items**.
   1. Select **Actions** ({{< icon name="ellipsis_v" >}}) > **Import from Jira**.
   1. Follow the on-screen instructions to complete the import process.
1. Verify the migration:
   1. Review the imported issues to ensure the project migrated to GitLab successfully.
   1. Test the features of your migrated Jira project in GitLab.
1. Adjust your workflows and settings:
   1. Customize your GitLab [project settings](../../project/settings/_index.md), such as:
      - [Description templates](../../project/description_templates.md).
      - [Labels](../../project/labels.md).
      - [Milestones](../../project/milestones/_index.md).
   1. Familiarize your team with the GitLab interface and any new workflows or processes introduced by the migration.
1. When you're satisfied with the migration, you can decommission your Jira instance and fully transition to GitLab.

## Write your own script

For full control over the migration process, you can write your own custom script that migrates
your Jira issues to GitLab in a way that suits your needs exactly. GitLab provides APIs to help
automate your migration:

- [REST API](../../../api/rest/_index.md)
- [GraphQL API](../../../api/graphql/_index.md)

To get started, familiarize yourself with the following GitLab API endpoints:

- [Issues](../../../api/issues.md)
- [Projects](../../../api/projects.md)
- [Labels](../../../api/labels.md)
- [Milestones](../../../api/milestones.md)

When writing your script, you need to map the Jira issue fields to their corresponding GitLab equivalents.

| Jira issue field | Possible GitLab equivalent |
|:----|:-------|
| Custom fields with a fixed number of options | Create a [scoped label](../../project/labels.md#scoped-labels) set with the field name as the scoped label key and the field values as the scoped label set values. For example, `input name::value1`, `input name::value2`. |
| Custom fields with text strings or integer values | Inject the custom field name and value into a section in the issue's description. |
| Status | Use [statuses](../../work_items/status.md). |
| Priority | Create a [scoped label](../../project/labels.md#scoped-labels) with the priority set as the scoped label key and the priority values as the scoped label set values. For example, `priority::1`. |
| Story Point | Map this value to the GitLab issue's **weight** value. |
| Sprint | Map this value to the GitLab issue's **iteration** value. This value is meaningful only for issues that have not been completed or are scheduled for a future sprint. Before importing the data, create the required [iterations](../../group/iterations/_index.md#iteration-cadences) in the parent group of your project. |

You might also need to handle parsing the Atlassian Document Format and mapping it to GitLab Flavored Markdown.
You can approach this in many different ways. For inspiration,
[review an example commit](https://gitlab.com/gitlab-org/gitlab/-/commit/4292a286d3f4ab26466f8e89125a4dbd194a9f3e).
This commit added a method to parse the Atlassian Document Format to GitLab Flavored Markdown for the Jira importer.

If you run GitLab locally, you can also convert Atlassian Document Format to GitLab Flavored Markdown
manually in the Rails console. To do so, execute:

```ruby
text = <document in Atlassian Document Format>
project = <project that wiki is in> or nil
Banzai.render(text, pipeline: :adf_commonmark, project: project)
```

## Related topics

- [Import and export settings](../../../administration/settings/import_and_export_settings.md).
- [Sidekiq configuration for imports](../../../administration/sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../../../administration/sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../../../administration/sidekiq/processing_specific_job_classes.md).
