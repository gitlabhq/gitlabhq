---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jenkins
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/246756) to GitLab Free in 13.7.

[Jenkins](https://www.jenkins.io/) is an open source automation server that supports
building, deploying and automating projects.

You should use a Jenkins integration with GitLab when:

- You plan to migrate your CI from Jenkins to [GitLab CI/CD](../ci/_index.md)
  in the future, but need an interim solution.
- You're invested in [Jenkins plugins](https://plugins.jenkins.io/) and choose
  to keep using Jenkins to build your apps.

This integration can trigger a Jenkins build when a change is pushed to GitLab.

You cannot use this integration to trigger GitLab CI/CD pipelines from Jenkins. Instead,
use the [pipeline triggers API endpoint](../api/pipeline_triggers.md) in a Jenkins job,
authenticated with a [pipeline trigger token](../ci/triggers/_index.md#create-a-pipeline-trigger-token).

After you have configured a Jenkins integration, you trigger a build in Jenkins
when you push code to your repository or create a merge request in GitLab. The
Jenkins pipeline status displays on merge request widgets and the GitLab
project's home page.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of the Jenkins integration for GitLab, see
[GitLab workflow with Jira issues and Jenkins pipelines](https://youtu.be/Jn-_fyra7xQ).

To configure a Jenkins integration with GitLab:

- Grant Jenkins access to the GitLab project.
- Configure the Jenkins server.
- Configure the Jenkins project.
- Configure the GitLab project.

## Grant Jenkins access to the GitLab project

1. Create a personal, project, or group access token.

   - [Create a personal access token](../user/profile/personal_access_tokens.md#create-a-personal-access-token)
     to use the token for all Jenkins integrations of that user.
   - [Create a project access token](../user/project/settings/project_access_tokens.md#create-a-project-access-token)
     to use the token at the project level only. For instance, you can revoke
     the token in a project without affecting Jenkins integrations in other projects.
   - [Create a group access token](../user/group/settings/group_access_tokens.md#create-a-group-access-token-using-ui)
     to use the token for all Jenkins integrations in all projects of that group.

1. Set the access token scope to **API**.
1. Copy the access token value to configure the Jenkins server.

## Configure the Jenkins server

Install and configure the Jenkins plugin to authorize the connection to GitLab.

1. On the Jenkins server, select **Manage Jenkins > Manage Plugins**.
1. Select the **Available** tab. Search for `gitlab-plugin` and select it to install.
   See the [Jenkins GitLab documentation](https://plugins.jenkins.io/gitlab-plugin/)
   for other ways to install the plugin.
1. Select **Manage Jenkins > Configure System**.
1. In the **GitLab** section, select **Enable authentication for '/project' end-point**.
1. Select **Add**, then choose **Jenkins Credential Provider**.
1. Select **GitLab API token** as the token type.
1. In **API Token**, [paste the access token value you copied from GitLab](#grant-jenkins-access-to-the-gitlab-project)
   and select **Add**.
1. Enter the GitLab server's URL in **GitLab host URL**.
1. To test the connection, select **Test Connection**.

   ![Jenkins plugin configuration](img/jenkins_gitlab_plugin_config_v8_3.png)

For more information, see
[Jenkins-to-GitLab authentication](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication).

## Configure the Jenkins project

Set up the Jenkins project you intend to run your build on.

1. On your Jenkins instance, select **New Item**.
1. Enter the project's name.
1. Select **Freestyle** or **Pipeline** and select **OK**.
   You should select a freestyle project, because the Jenkins plugin updates the build status on
   GitLab. In a pipeline project, you must configure a script to update the status on GitLab.
1. Choose your GitLab connection from the dropdown list.
1. Select **Build when a change is pushed to GitLab**.
1. Select the following checkboxes:
   - **Accepted Merge Request Events**
   - **Closed Merge Request Events**
1. Specify how the build status is reported to GitLab:
   - If you created a freestyle project, in the **Post-build Actions** section,
     choose **Publish build status to GitLab**.
   - If you created a pipeline project, you must use a Jenkins Pipeline script to
     update the status on GitLab.

     Example Jenkins Pipeline script:

      ```groovy
      pipeline {
         agent any

         stages {
            stage('gitlab') {
               steps {
                  echo 'Notify GitLab'
                  updateGitlabCommitStatus name: 'build', state: 'pending'
                  updateGitlabCommitStatus name: 'build', state: 'success'
               }
            }
         }
      }
      ```

      For more Jenkins Pipeline script examples, see the
      [Jenkins GitLab plugin repository on GitHub](https://github.com/jenkinsci/gitlab-plugin#scripted-pipeline-jobs).

## Configure the GitLab project

Configure the GitLab integration with Jenkins in one of the following ways.

### With a Jenkins server URL

You should use this approach for Jenkins integrations if you can provide GitLab
with your Jenkins server URL and authentication information.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Jenkins**.
1. Select the **Active** checkbox.
1. Select the events you want GitLab to trigger a Jenkins build for:
   - Push
   - Merge request
   - Tag push
1. Enter the **Jenkins server URL**.
1. Optional. Clear the **Enable SSL verification** checkbox to disable [SSL verification](../user/project/integrations/_index.md#ssl-verification).
1. Enter the **Project name**.
   The project name should be URL-friendly, where spaces are replaced with underscores. To ensure
   the project name is valid, copy it from your browser's address bar while viewing the Jenkins
   project.
1. If your Jenkins server requires authentication, enter the **Username** and **Password**.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

### With a webhook

If you cannot [provide GitLab with your Jenkins server URL and authentication information](#with-a-jenkins-server-url), you can configure a webhook to integrate GitLab and Jenkins.

1. In the configuration of your Jenkins job, in the GitLab configuration section, select **Advanced**.
1. Under **Secret Token**, select **Generate**.
1. Copy the token, and save the job configuration.
1. In GitLab:
   - [Create a webhook for your project](../user/project/integrations/webhooks.md#configure-webhooks).
   - Enter the trigger URL (such as `https://JENKINS_URL/project/YOUR_JOB`).
   - Paste the token in **Secret Token**.
1. To test the webhook, select **Test**.

## Related topics

- [GitLab Jenkins Integration](https://about.gitlab.com/solutions/jenkins/)
- [How to set up Jenkins on your local machine](../development/integrations/jenkins.md)
- [How to migrate from Jenkins to GitLab CI/CD](../ci/migration/jenkins.md)
- [Jenkins to GitLab: The ultimate guide to modernizing your CI/CD environment](https://about.gitlab.com/blog/2023/11/01/jenkins-gitlab-ultimate-guide-to-modernizing-cicd-environment/?utm_campaign=devrel&utm_source=twitter&utm_medium=social&utm_budget=devrel)

## Troubleshooting

### Error: `Connection failed. Please check your settings`

When you configure GitLab, you might get an error that states `Connection failed. Please check your settings`.

This issue has multiple possible causes and solutions:

| Cause                                                            | Workaround  |
|------------------------------------------------------------------|-------------|
| GitLab is unable to reach your Jenkins instance at the address.  | For GitLab Self-Managed, ping the Jenkins instance at the domain provided on the GitLab instance.  |
| The Jenkins instance is at a local address and is not included in the [GitLab installation's allowlist](../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).| Add the instance to the GitLab installation's allowlist.  |
| The credentials for the Jenkins instance do not have sufficient access or are invalid.| Grant the credentials sufficient access or create valid credentials.  |
|The **Enable authentication for `/project` end-point** checkbox is not selected in your [Jenkins plugin configuration](#configure-the-jenkins-server)| Select the checkbox.  |

### Error: `Could not connect to the CI server`

You might get an error that states `Could not connect to the CI server` in a merge
request if GitLab did not receive a build status update from Jenkins through the
[Commit Status API](../api/commits.md#commit-status).

This issue occurs when Jenkins is not properly configured or there is an error
reporting the status through the API.

To fix this issue:

1. [Configure the Jenkins server](#configure-the-jenkins-server) for GitLab API access.
1. [Configure the Jenkins project](#configure-the-jenkins-project), and make sure
   that, if you create a freestyle project, you choose the "Publish build status to GitLab"
   post-build action.

### Merge request event does not trigger a Jenkins pipeline

This issue might occur when the request exceeds the [webhook timeout limit](../user/gitlab_com/_index.md#webhooks),
which is set to 10 seconds by default.

For this issue, check:

- The integration webhook logs for request failures.
- `/var/log/gitlab/gitlab-rails/production.log` for messages like:

  ```plaintext
  WebHook Error => Net::ReadTimeout
  ```

  or

  ```plaintext
  WebHook Error => execution expired
  ```

On GitLab Self-Managed, you can fix this issue by [increasing the webhook timeout value](../administration/instance_limits.md#webhook-timeout).

### Enable job logs in Jenkins

To troubleshoot an integration issue, you can enable job logs in Jenkins to get
more details about your builds.

To enable job logs in Jenkins:

1. Go to **Dashboard > Manage Jenkins > System Log**.
1. Select **Add new log recorder**.
1. Enter a name for the log recorder.
1. On the next screen, select **Add** and enter `com.dabsquared.gitlabjenkins`.
1. Make sure that the Log Level is **All** and select **Save**.

To view your logs:

1. Run a build.
1. Go to **Dashboard > Manage Jenkins > System Log**.
1. Select your logger and check the logs.
