# Jenkins CI service **(STARTER)**

NOTE: **Note:**
This documentation focuses only on how to **configure** a Jenkins *integration* with
GitLab. Learn how to **migrate** from Jenkins to GitLab CI/CD in our
[Migrating from Jenkins](../ci/jenkins/index.md) documentation.

From GitLab, you can trigger a Jenkins build when you push code to a repository, or when a merge
request is created. In return, Jenkins shows the pipeline status on merge requests widgets and
on the GitLab project's home page.

To better understand GitLab's Jenkins integration, watch the following video:

- [GitLab workflow with Jira issues and Jenkins pipelines](https://youtu.be/Jn-_fyra7xQ)
Use the Jenkins integration with GitLab when:

- You plan to migrate your CI from Jenkins to [GitLab CI/CD](../ci/README.md) in the future, but
need an interim solution.
- You're invested in [Jenkins Plugins](https://plugins.jenkins.io/) and choose to keep using Jenkins
to build your apps.

For a real use case, read the blog post [Continuous integration: From Jenkins to GitLab using Docker](https://about.gitlab.com/blog/2017/07/27/docker-my-precious/).

Moving from a traditional CI plug-in to a single application for the entire software development
life cycle can decrease hours spent on maintaining toolchains by 10% or more. For more details, see
the ['GitLab vs. Jenkins' comparison page](https://about.gitlab.com/devops-tools/jenkins-vs-gitlab.html).

## Configure GitLab integration with Jenkins

GitLab's Jenkins integration requires installation and configuration in both GitLab and Jenkins.
In GitLab, you need to grant Jenkins access to the relevant projects. In Jenkins, you need to
install and configure several plugins.

### GitLab requirements

- [Grant Jenkins permission to GitLab project](#grant-jenkins-access-to-gitlab-project)
- [Configure GitLab API access](#configure-gitlab-api-access)
- [Configure the GitLab project](#configure-the-gitlab-project)

### Jenkins requirements

- [Configure the Jenkins server](#configure-the-jenkins-server)
- [Configure the Jenkins project](#configure-the-jenkins-project)

## Grant Jenkins access to GitLab project

Grant a GitLab user access to the select GitLab projects.

1. Create a new GitLab user, or choose an existing GitLab user.

   This account will be used by Jenkins to access the GitLab projects. We recommend creating a GitLab
   user for only this purpose. If you use a person's account, and their account is deactivated or
   deleted, the GitLab-Jenkins integration will stop working.

1. Grant the user permission to the GitLab projects.

   If you're integrating Jenkins with many GitLab projects, consider granting the user global
   Admin permission. Otherwise, add the user to each project, and grant Developer permission.

## Configure GitLab API access

Create a personal access token to authorize Jenkins' access to GitLab.

1. Log in to GitLab as the user to be used with Jenkins.
1. Click your avatar, then **Settings.
1. Click **Access Tokens** in the sidebar.
1. Create a personal access token with the **API** scope checkbox checked. For more details, see
   [Personal access tokens](../user/profile/personal_access_tokens.md).
1. Record the personal access token's value, because it's required in [Configure the Jenkins server](#configure-the-jenkins-server).

## Configure the Jenkins server

Install and configure the Jenkins plugins. Both plugins must be installed and configured to
authorize the connection to GitLab.

1. On the Jenkins server, go to **Manage Jenkins > Manage Plugins**.
1. Install the [Jenkins GitLab Plugin](https://wiki.jenkins.io/display/JENKINS/GitLab+Plugin).
1. Go to **Manage Jenkins > Configure System**.
1. In the **GitLab** section, check the **Enable authentication for ‘/project’ end-point** checkbox.
1. Click **Add**, then choose **Jenkins Credential Provider**.
1. Choose **GitLab API token** as the token type.
1. Enter the GitLab personal access token's value in the **API Token** field and click **Add**.
1. Enter the GitLab server's URL in the **GitLab host URL** field.
1. Click **Test Connection**, ensuring the connection is successful before proceeding.

For more information, see GitLab Plugin documentation about
[Jenkins-to-GitLab authentication](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication).

![Jenkins GitLab plugin configuration](img/jenkins_gitlab_plugin_config.png)

## Configure the Jenkins project

Set up the Jenkins project you’re going to run your build on.

1. On your Jenkins instance, go to **New Item**.
1. Enter the project's name.
1. Choose between **Freestyle** or **Pipeline** and click **OK**.
    We recommend a Freestyle project, because the Jenkins plugin will update the build status on
    GitLab. In a Pipeline project, you must configure a script to update the status on GitLab.
1. Choose your GitLab connection from the dropdown.
1. Check the **Build when a change is pushed to GitLab** checkbox.
1. Check the following checkboxes:
   - **Accepted Merge Request Events**
   - **Closed Merge Request Events**
1. Specify how build status is reported to GitLab:
   - If you created a **Freestyle** project, in the **Post-build Actions** section, choose
   **Publish build status to GitLab**.
   - If you created a **Pipeline** project, you must use a Jenkins Pipeline script to update the status on
   GitLab.

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

## Configure the GitLab project

Configure the GitLab integration with Jenkins.

1. Create a new GitLab project or choose an existing one.
1. Go to **Settings > Integrations**, then select **Jenkins CI**.
1. Turn on the **Active** toggle.
1. Select the events you want GitLab to trigger a Jenkins build for:
   - Push
   - Merge request
   - Tag push
1. Enter the **Jenkins URL**.
1. Enter the **Project name**.

   The project name should be URL-friendly, where spaces are replaced with underscores. To ensure
   the project name is valid, copy it from your browser's address bar while viewing the Jenkins
   project.
1. Enter the **Username** and **Password** if your Jenkins server requires
   authentication.
1. Click **Test settings and save changes**. GitLab tests the connection to Jenkins.

## Plugin functional overview

GitLab does not contain a database table listing commits. Commits are always
read from the repository directly. Therefore, it's not possible to retain the
build status of a commit in GitLab. This is overcome by requesting build
information from the integrated CI tool. The CI tool is responsible for creating
and storing build status for Commits and Merge Requests.

### Steps required to implement a similar integration

**Note:**
All steps are implemented using AJAX requests on the merge request page.

1. In order to display the build status in a merge request you must create a project service in GitLab.
1. Your project service will do a (JSON) query to a URL of the CI tool with the SHA1 of the commit.
1. The project service builds this URL and payload based on project service settings and knowledge of the CI tool.
1. The response is parsed to give a response in GitLab (success/failed/pending).

## Troubleshooting

### Error in merge requests - "Could not connect to the CI server"

This integration relies on Jenkins reporting the build status back to GitLab via
the [Commit Status API](../api/commits.md#commit-status).

The error 'Could not connect to the CI server' usually means that GitLab did not
receive a build status update via the API. Either Jenkins was not properly
configured or there was an error reporting the status via the API.

1. [Configure the Jenkins server](#configure-the-jenkins-server) for GitLab API access
1. [Configure the Jenkins project](#configure-the-jenkins-project), including the
   'Publish build status to GitLab' post-build action.

### Merge Request event does not trigger a Jenkins Pipeline

Check [service hook logs](../user/project/integrations/overview.md#troubleshooting-integrations) for request failures or check the `/var/log/gitlab/gitlab-rails/production.log` file for messages like:

```plaintext
WebHook Error => Net::ReadTimeout
```

or

```plaintext
WebHook Error => execution expired
```

If those are present, the request is exceeding the
[webhook timeout](../user/project/integrations/webhooks.md#receiving-duplicate-or-multiple-webhook-requests-triggered-by-one-event),
which is set to 10 seconds by default.

To fix this the `gitlab_rails['webhook_timeout']` value will need to be increased
in the `gitlab.rb` config file, followed by the [`gitlab-ctl reconfigure` command](../administration/restart_gitlab.md).

If you don't find the errors above, but do find *duplicate* entries like below (in `/var/log/gitlab/gitlab-rail`), this
could also indicate that [webhook requests are timing out](../user/project/integrations/webhooks.md#receiving-duplicate-or-multiple-webhook-requests-triggered-by-one-event):

```plaintext
2019-10-25_04:22:41.25630 2019-10-25T04:22:41.256Z 1584 TID-ovowh4tek WebHookWorker JID-941fb7f40b69dff3d833c99b INFO: start
2019-10-25_04:22:41.25630 2019-10-25T04:22:41.256Z 1584 TID-ovowh4tek WebHookWorker JID-941fb7f40b69dff3d833c99b INFO: start
```
