---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: Jira migration options
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You have several options to migrate your Jira projects to GitLab. Before you decide on a migration strategy,
first decide if you even need to move your Jira issues to GitLab. In many cases, the Jira issue data is no longer
relevant or actionable. By starting fresh in GitLab, you can focus on setting up your processes and workflows to
maximize the advantages of using GitLab.

If you opt to migrate your Jira issues, you can choose from several migration options:

- Use GitLab Jira importer.
- Import a CSV file.
- Let GitLab Professional Services handle the migration for you.
- Use a third-party service to build a one-way or two-way data synchronization process.
- Use a third-party script.
- Write your own script.

## Use GitLab Jira importer

GitLab has a built-in tool to import your Jira issue data. To use the GitLab Jira importer:

1. [Configure the GitLab Jira issues integration in your target project](../../../integration/jira/configure.md#configure-the-integration)
1. [Import your Jira project issues to GitLab](../import/jira.md)

Alternatively, you can watch a complete demo of the process: <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Import Jira project issues to GitLab](https://www.youtube.com/watch?v=OTJdJWmODFA)
<!-- Video published on 2023-07-27 -->

## Import a CSV file

To import the Jira issue data from a CSV file into your GitLab project:

1. Export your Jira data:
   1. Log in to your Jira instance and go to the project you want to migrate.
   1. Export the project data as a CSV file.
   1. Edit your CSV file to match the [column names required for the GitLab CSV importer](../issues/csv_import.md).
      - Only `title`, `description`, `due_date`, and `milestone` are imported.
      - You can [add quick actions to the description field](../quick_actions.md) to set other issue metadata automatically during the import process.
1. Create a new GitLab group and project:
   1. Sign in to your GitLab account and [create a group](../../group/_index.md#create-a-group) to host your migrated projects.
   1. In the new group, [create a new project](../_index.md#create-a-blank-project) to hold the migrated Jira issues.
1. Import the Jira data into GitLab:
   1. In your new GitLab project, on the left sidebar, select **Plan > Issues**.
   1. Select **Actions** (**{ellipsis_v}**) **> Import from Jira**.
   1. Follow the on-screen instructions to complete the import process.
1. Verify the migration:
   1. Review the imported issues to ensure the project migrated to GitLab successfully.
   1. Test the features of your migrated Jira project in GitLab.
1. Adjust your workflows and settings:
   1. Customize your GitLab [project settings](../settings/_index.md), such as [description templates](../description_templates.md), [labels](../labels.md), and [milestones](../milestones/_index.md), to match your team's needs.
   1. Familiarize your team with the GitLab interface and any new workflows or processes introduced by the migration.
1. Decommission your Jira instance:
   1. When you're satisfied with the migration, you can decommission your Jira instance and fully transition to GitLab.

## Let GitLab Professional Services handle the migration for you

For a high-level overview of the Jira migration service, see the [Jira Migration Service](https://drive.google.com/file/d/1p0rv02OnjfSiNoeDT2u4MhviozS--Yan/view) data sheet.

To get a personalized quote, visit the [GitLab Professional Services](https://about.gitlab.com/services/) page and select **Request Service**.

## Establish a one-way or two-way data synchronization using a third-party service

To establish a one-way or two-way data synchronization between Jira and GitLab, you can use the following third-party services:

- **Unito.io**: [GitLab + Jira integration documentation](https://guide.unito.io/gitlab-jira-integration), [GitLab + Jira Two-Way Sync Marketplace Add-On](https://marketplace.atlassian.com/apps/1218054/gitlab-jira-two-way-sync?tab=overview&hosting=cloud)
- **Getint**: [GitLab Jira sync Marketplace Add-on](https://marketplace.atlassian.com/apps/1223999/gitlab-jira-sync-integration-by-getint?tab=overview&hosting=cloud)

## Use a third-party script

You can use one of the available open-source migration scripts to help you migrate your Jira issues to GitLab.

Many of our customers have had success using [`jira2gitlab`](https://github.com/swingbit/jira2gitlab).

View a complete demo of the process: <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Migrating from Jira to GitLab with Jira2GitLab](https://www.youtube.com/watch?v=aJfnTZrS4t4)
<!-- Video published on 2024-01-09 -->

## Use a first-party script

[GitLab Professional Services](https://about.gitlab.com/services/) has built their fork of the previously-mentioned `jira2gitlab` script, `Jira2Lab`:

- Blog post: [Seamlessly migrate from Jira to GitLab with Jira2Lab at scale](https://about.gitlab.com/blog/2024/10/10/seamlessly-migrate-from-jira-to-gitlab-with-jira2lab-at-scale/)
- [Repository](https://gitlab.com/gitlab-org/professional-services-automation/tools/migration/jira2lab)

As stated in the `Jira2Lab` README:

> We encourage users to compare both tools to best meet their migration needs.

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

When writing your script, you need to map the Jira issue fields to their corresponding GitLab equivalents. Here are some tips:

- **Custom fields with a fixed number of options**: Create a [scoped label](../labels.md#scoped-labels) set with the field name as the scoped label key and the field values as the scoped label set values (for example, `input name::value1`, `input name::value2`).
- **Custom fields with text strings or integer values**: Inject the custom field name and value into a section in the issue's description.
- **Status**: Create a [scoped label](../labels.md#scoped-labels) with the status set as the scoped label key and the status values as the scoped label set values (for example, `status::in progress`).
- **Priority**: Create a [scoped label](../labels.md#scoped-labels) with the priority set as the scoped label key and the priority values as the scoped label set values (for example, `priority::1`).
- **Story Point**: Map this value to the GitLab issue's **weight** value.
- **Sprint**: Map this value to the GitLab issue's **iteration** value. This value is meaningful
  only for issues that have not been completed or are scheduled for a future sprint. Before importing
  the data, create the required [iterations](../../group/iterations/_index.md#iteration-cadences) in the
  parent group of your project.

You might also need to handle parsing the Atlassian Document Format and mapping it to GitLab Flavored Markdown.
You can approach this in many different ways. For inspiration,
[review an example commit](https://gitlab.com/gitlab-org/gitlab/-/commit/4292a286d3f4ab26466f8e89125a4dbd194a9f3e).
This commit added a method to parse the Atlassian Document Format to GitLab Flavored Markdown for the GitLab Jira importer.

If you run GitLab locally, you can also convert Atlassian Document Format to GitLab Flavored Markdown
manually in the Rails console. To do so, execute:

```ruby
text = <document in Atlassian Document Format>
project = <project that wiki is in> or nil
Banzai.render(text, pipeline: :adf_commonmark, project: project)
```
