---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Atlassian Bamboo Service **(FREE)**

GitLab provides integration with Atlassian Bamboo for continuous integration.
When configured, pushes to a project trigger a build in Bamboo automatically.
Merge requests also display CI/CD status showing whether the build is pending,
failed, or completed successfully. It also provides a link to the Bamboo build
page for more information.

Bamboo doesn't quite provide the same features as a traditional build system when
it comes to accepting webhooks and commit data. There are a few things that
need to be configured in a Bamboo build plan before GitLab can integrate.

## Setup

### Complete these steps in Bamboo

1. Navigate to a Bamboo build plan and choose **Configure plan** from the **Actions**
   dropdown.
1. Select the **Triggers** tab.
1. Click **Add trigger**.
1. Enter a description such as **GitLab trigger**.
1. Choose **Repository triggers the build when changes are committed**.
1. Select the checkbox for one or more repositories.
1. Enter the GitLab IP address in the **Trigger IP addresses** box. This is a
   list of IP addresses that are allowed to trigger Bamboo builds.
1. Save the trigger.
1. In the left pane, select a build stage. If you have multiple build stages
   you want to select the last stage that contains the Git checkout task.
1. Select the **Miscellaneous** tab.
1. Under **Pattern Match Labeling** put `${bamboo.repository.revision.number}`
   in the **Labels** box.
1. Save

Bamboo is now ready to accept triggers from GitLab. Next, set up the Bamboo
service in GitLab.

### Complete these steps in GitLab

1. Navigate to the project you want to configure to trigger builds.
1. Navigate to the [Integrations page](overview.md#accessing-integrations)
1. Click **Atlassian Bamboo**.
1. Ensure that the **Active** toggle is enabled.
1. Enter the base URL of your Bamboo server. `https://bamboo.example.com`
1. Enter the build key from your Bamboo build plan. Build keys are typically made
   up from the Project Key and Plan Key that are set on project/plan creation and
   separated with a dash (`-`), for example **PROJ-PLAN**. This is a short, all
   uppercase identifier that is unique. When viewing a plan in Bamboo, the
   build key is also shown in the browser URL, for example `https://bamboo.example.com/browse/PROJ-PLAN`.
1. If necessary, enter username and password for a Bamboo user that has
   access to trigger the build plan. Leave these fields blank if you do not require
   authentication.
1. Save or optionally click **Test Settings**. Please note that **Test Settings**
   actually triggers a build in Bamboo.

## Troubleshooting

### Builds not triggered

If builds are not triggered, ensure you entered the right GitLab IP address in
Bamboo under **Trigger IP addresses**. Also check [service hook logs](overview.md#troubleshooting-integrations) for request failures.

### Advanced Atlassian Bamboo features not available in GitLab UI

Advanced Atlassian Bamboo features are not compatible with GitLab. These features
include, but are not limited to, the ability to watch the build logs from the GitLab UI.
