---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Atlassian Bamboo integration **(FREE)**

You can automatically trigger builds in Atlassian Bamboo when you push changes
to your project in GitLab.

When this integration is configured, merge requests also display the following information:

- A CI/CD status that shows if the build is pending, failed, or has completed successfully.
- A link to the Bamboo build page for more information.

Bamboo doesn't provide the same features as a traditional build system when
accepting webhooks and commit data. You must configure a Bamboo
build plan before you configure the integration in GitLab.

## Configure Bamboo

1. In Bamboo, go to a build plan and choose **Actions > Configure plan**.
1. Select the **Triggers** tab.
1. Select **Add trigger**.
1. Enter a description like `GitLab trigger`.
1. Select **Repository triggers the build when changes are committed**.
1. Select the checkbox for one or more repositories.
1. Enter the GitLab IP address in **Trigger IP addresses**. These IP addresses
   are allowed to trigger Bamboo builds.
1. Save the trigger.
1. In the left pane, select a build stage. If you have multiple build stages,
   select the last stage that contains the Git checkout task.
1. Select the **Miscellaneous** tab.
1. Under **Pattern Match Labeling** enter `${bamboo.repository.revision.number}`
   in **Labels**.
1. Select **Save**.

Bamboo is ready to accept triggers from GitLab. Next, set up the Bamboo
integration in GitLab.

## Configure GitLab

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Atlassian Bamboo**.
1. Ensure the **Active** checkbox is selected.
1. Enter the base URL of your Bamboo server. For example, `https://bamboo.example.com`.
1. Optional. Clear the **Enable SSL verification** checkbox to disable [SSL verification](overview.md#ssl-verification).
1. Enter the [build key](#identify-the-bamboo-build-plan-build-key) from your Bamboo
   build plan.
1. If necessary, enter a username and password for a Bamboo user that has
   access to trigger the build plan. Leave these fields blank if you do not require
   authentication.
1. Optional. To test the configuration and trigger a build in Bamboo,
   select **Test Settings**.
1. Select **Save changes**.

### Identify the Bamboo build plan build key

A build key is a unique identifier typically made up from the project key and
plan key.
Build keys are short, all uppercase, and separated with a dash (`-`),
for example `PROJ-PLAN`.

The build key is included in the browser URL when you view a plan in
Bamboo. For example, `https://bamboo.example.com/browse/PROJ-PLAN`.

## Troubleshooting

### Builds not triggered

If builds are not triggered, ensure you entered the right GitLab IP address in
Bamboo under **Trigger IP addresses**. Also check [service hook logs](overview.md#troubleshooting-integrations) for request failures.

### Advanced Atlassian Bamboo features not available in GitLab UI

Advanced Atlassian Bamboo features are not compatible with GitLab. These features
include, but are not limited to, the ability to watch the build logs from the GitLab UI.
