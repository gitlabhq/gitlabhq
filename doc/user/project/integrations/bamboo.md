---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Atlassian Bamboo
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can automatically trigger builds in Atlassian Bamboo when you push changes
to your project in GitLab.

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

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Atlassian Bamboo**.
1. Ensure the **Active** checkbox is selected.
1. Enter the base URL of your Bamboo server. For example, `https://bamboo.example.com`.
1. Optional. Clear the **Enable SSL verification** checkbox to disable [SSL verification](_index.md#ssl-verification).
1. Enter the [build key](#identify-the-bamboo-build-plan-build-key) from your Bamboo
   build plan.
1. If necessary, enter a username and password for a Bamboo user that has
   access to trigger the build plan. Leave these fields blank if you do not require
   authentication.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

### Identify the Bamboo build plan build key

A build key is a unique identifier typically made up from the project key and
plan key.
Build keys are short, all uppercase, and separated with a dash (`-`),
for example `PROJ-PLAN`.

The build key is included in the browser URL when you view a plan in
Bamboo. For example, `https://bamboo.example.com/browse/PROJ-PLAN`.

## Update Bamboo build status in GitLab

You can use a script that uses the [commit status API](../../../api/commits.md#set-the-pipeline-status-of-a-commit)
and Bamboo build variables to:

- Update the commit with the build status.
- Add the Bamboo build plan URL as the commit's `target_url`.

For example:

1. Create an [access token](../../../api/rest/authentication.md#personalprojectgroup-access-tokens) in GitLab with `:api` permissions.
1. Save the token as a `$GITLAB_TOKEN` variable in Bamboo.
1. Add the following script as a final task to the Bamboo plan's jobs:

   ```shell
   #!/bin/bash

   # Script to update CI status on GitLab.
   # Add this script as final inline script task in a Bamboo job.
   #
   # General documentation: https://docs.gitlab.com/ee/user/project/integrations/bamboo.html
   # Fix inspired from https://gitlab.com/gitlab-org/gitlab/-/issues/34744

   # Stop at first error
   set -e

   # Access token. Set this as a CI variable in Bamboo.
   #GITLAB_TOKEN=

   # Status
   cistatus="failed"
   if [ "${bamboo_buildFailed}" = "false" ]; then
     cistatus="success"
   fi

   repo_url="${bamboo_planRepository_repositoryUrl}"

   # Check if we use SSH or HTTPS
   protocol=${repo_url::4}
   if [ "$protocol" == "git@" ]; then
     repo=${repo_url:${#protocol}};
     gitlab_url=${repo%%:*};
   else
     protocol="https://"
     repo=${repo_url:${#protocol}};
     gitlab_url=${repo%%/*};
   fi

   start=$((${#gitlab_url} + 1)) # +1 for the / (https) or : (ssh)
   end=$((${#repo} - $start -4)) # -4 for the .git
   repo=${repo:$start:$end}
   repo=$(echo "$repo" | sed "s/\//%2F/g")

   # Send request
   url="https://${gitlab_url}/api/v4/projects/${repo}/statuses/${bamboo_planRepository_revision}?state=${cistatus}&target_url=${bamboo_buildResultsUrl}"
   echo "Sending request to $url"
   curl --fail --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$url"
   ```

## Troubleshooting

### Builds not triggered

If builds are not triggered, ensure you entered the right GitLab IP address in
Bamboo under **Trigger IP addresses**. Also, check the integration webhook logs for request failures.

### Advanced Atlassian Bamboo features not available in GitLab UI

Advanced Atlassian Bamboo features are not compatible with GitLab. These features
include, but are not limited to, the ability to watch the build logs from the GitLab UI.
