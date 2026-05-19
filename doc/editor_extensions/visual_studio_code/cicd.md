---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use the GitLab for VS Code extension to manage CI/CD pipelines directly in your IDE.
title: CI/CD pipelines in the VS Code extension
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895) in GitLab VS Code extension 6.14.0 for GitLab 18.1 and later.
- Added [downstream pipeline logs](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895) for GitLab 18.1 and later.

{{< /history >}}

If your project uses GitLab CI/CD pipelines, you can use the GitLab for VS Code extension to start,
monitor, and update pipelines directly in your IDE.

## Prerequisites

- [Authenticate the extension](setup.md#connect-to-gitlab) and connect to a repository on GitLab.

## Monitor and manage pipelines

Use the extension to monitor and manage pipelines for your project.

Prerequisites:

- Your project uses CI/CD pipelines.
- A merge request exists for your current Git branch.
- The most recent commit on your current Git branch has a CI/CD pipeline.

### View pipeline status

To view the status of your branch pipeline, check the bottom status bar in VS Code.

![The bottom status bar, showing the most recent pipeline has failed.](img/status_bar_pipeline_v17_6.png)

Possible statuses include:

- Pipeline canceled
- Pipeline failed
- Pipeline passed
- Pipeline pending
- Pipeline running
- Pipeline skipped
- No pipeline, if a pipeline has not run yet.

### Manage pipelines

To start, monitor, and debug CI/CD pipelines in GitLab:

1. In VS Code, in the bottom status bar, select the pipeline status to open the **Command Palette**
   and access the available actions.
1. Select your desired action and follow the prompts:

   - **Create New Pipeline from Current Branch**
   - **Cancel Last Pipeline**
   - **Download Artifacts from Latest Pipeline**
   - **Retry Last Pipeline**
   - **View Latest Pipeline on GitLab**

### View CI/CD job output

To view the output for a CI/CD job for your current branch:

1. In the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
1. Expand **For current branch** to view the most recent pipeline.
1. Select a job to open it in a new VS Code tab:

   ![A pipeline containing CI/CD jobs that passed and failed.](img/view_job_output_v17_6.png)

To open a downstream pipeline's job log:

1. Find downstream pipelines under the list of branch pipeline jobs.
1. Select the arrow icons to expand or collapse the downstream pipeline information.
1. Select a downstream pipeline to open the job log in a new VS Code tab.

### Manage pipeline alerts

The extension can display an alert in VS Code when a pipeline for your current branch completes:

![Alert showing a pipeline failure](img/pipeline_alert_v19_0.png)

To turn pipeline alerts on or off:

1. In VS Code, open the **Settings** editor:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. Depending on your configuration, select either **User** or **Workspace** settings.
1. Select **Extensions** > **GitLab** > **Other**.
1. Under **GitLab: Show Pipeline Update Notifications**, select or deselect the checkbox.

## Manage your CI/CD configuration

The extension also provides tools you can use to create and manage the CI/CD configuration for
your project.

### Autocomplete CI/CD variables

When you write or edit your CI/CD configuration file, use variable autocompletion to find
variables quickly.

Prerequisites:

- The name of your CI/CD configuration file starts with `.gitlab-ci` and ends with `.yml` or `.yaml`.
  For example, `.gitlab-ci.yml` or `.gitlab-ci.production.yml`

To autocomplete a variable:

1. In VS Code, open your `.gitlab-ci.yml` file, and ensure the file's tab is in focus.
1. Begin entering the variable name. The extension displays autocomplete options.
1. Select an option to use it:

   ![Autocomplete options shown for a string](img/ci_variable_autocomplete_v16_6.png)

### Test GitLab CI/CD configuration

To test your project's GitLab CI/CD configuration locally:

1. In VS Code, open your `.gitlab-ci.yml` file, and ensure the file's tab is in focus.
1. Open the **Command Palette**:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Validate GitLab CI Config` and press <kbd>Enter</kbd>.

The extension shows an alert if it detects a problem with your configuration.

### Show merged configuration file

To see a preview of your merged CI/CD configuration file, with all `includes` and references resolved:

1. In VS Code, open your `.gitlab-ci.yml` file, and ensure the file's tab is in focus.
1. In the upper right, select **Show Merged GitLab CI/CD Configuration**:

   ![The VS Code application, showing the icon for viewing merged results.](img/show_merged_configuration_v17_6.png)

VS Code opens a new tab (`.gitlab-ci (Merged).yml`) with full information.

## Related topics

- [Use CI/CD to build your application](../../topics/build_your_application.md)
