# How to run Jenkins in development environment (on OSX) **(STARTER)**

This is a step by step guide on how to set up [Jenkins](https://jenkins.io/) on your local machine and connect to it from your GitLab instance. GitLab triggers webhooks on Jenkins, and Jenkins is connects to GitLab using the API. By running both applications on the same machine, we can make sure they are able to access each other.

## Install Jenkins

Install Jenkins and start the service using Homebrew.

```shell
brew install jenkins
brew services start jenkins
```

## Configure GitLab

GitLab does not allow requests to localhost or the local network by default. When running Jenkins on your local machine, you need to enable local access.

1. Log into your GitLab instance as an admin.
1. Go to **{admin}** **Admin Area > Settings > Network**.
1. Expand `Outbound requests` and check the following checkboxes:

- **Allow requests to the local network from web hooks and services**
- **Allow requests to the local network from system hooks**

For more details about GitLab webhooks, see [Webhooks and insecure internal web services](../../security/webhooks.md).

Jenkins uses the GitLab API and needs an access token.

1. Log in to your GitLab instance.
1. Click on your profile picture, then click **Settings**.
1. Click **Access Tokens**.
1. Create a new Access Token with the **API** scope enabled. Note the value of the token.

## Configure Jenkins

Configure your GitLab API connection in Jenkins.

1. Make sure the GitLab plugin is installed on Jenkins. You can manage plugins in **Manage Jenkins > Manage Plugins**.
1. Set up the GitLab connection: Go to **Manage Jenkins > Configure System**, find the **GitLab** section and check the `Enable authentication for '/project' end-point` checkbox.
1. To add your credentials, click **Add** then choose **Jenkins Credential Provider**.
1. Choose **GitLab API token** as the type of token.
1. Paste your GitLab access token and click **Add**.
1. Choose your credentials from the dropdown menu.
1. Add your GitLab host URL. Normally `http://localhost:3000/`.
1. Click **Save Settings**.

For more details, see [GitLab documentation about Jenkins CI](../../integration/jenkins.md).

## Configure Jenkins Project

Set up the Jenkins project you are going to run your build on.

1. On your Jenkins instance, go to **New Item**.
1. Pick a name, choose **Pipeline** and click **ok**.
1. Choose your GitLab connection from the dropdown.
1. Check the **Build when a change is pushed to GitLab** checkbox.
1. Check the following checkboxes:

- **Accepted Merge Request Events**
- **Closed Merge Request Events**

1. Updating the status on GitLab must be done by a pipeline script. Add GitLab update steps, using the following as an example:

**Example Pipeline Script:**

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

## Configure your GitLab project

To activate the Jenkins service you must have a Starter subscription or higher.

1. Go to your project's page, then **Settings > Integrations > Jenkins CI**.
1. Check the `Active` checkbox and the triggers for `Push` and `Merge request`.
1. Fill in your Jenkins host, project name, username and password and click **Test settings and save changes**.

## Test your setup

Make a change in your repository and open an MR. In your Jenkins project it should have triggered a new build and on your MR, there should be a widget saying "Pipeline #NUMBER passed". It will also include a link to your Jenkins build.

### Run QA test

The [jenkins_build_status_spec](https://gitlab.com/gitlab-org/gitlab/-/blob/v12.9.0-ee/qa/qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb) performs an end-to-end test of the Jenkins setup using [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa).

To run the test against your GDK, follow the [run QA tests against your GDK setup](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/run_qa_against_gdk.md#run-qa-tests-against-your-gdk-setup) instructions.

The following environment variables are required to run the test:

- `GITLAB_USERNAME`
- `GITLAB_PASSWORD`
- `GITLAB_ADMIN_USERNAME`
- `GITLAB_ADMIN_PASSWORD`

Run the test in the **qa** directory using:

```shell
bundle exec bin/qa Test::Instance::All http://<your_network_ip_address>:3000 -- qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb --tag quarantine
```
