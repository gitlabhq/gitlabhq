---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: How to run Jenkins in development environment (on macOS)
---

This is a step by step guide on how to set up [Jenkins](https://www.jenkins.io/) on your local machine and connect to it from your GitLab instance. GitLab triggers webhooks on Jenkins, and Jenkins connects to GitLab using the API. By running both applications on the same machine, we can make sure they are able to access each other.

For configuring an existing Jenkins integration, read [Jenkins CI service](../../integration/jenkins.md).

## Install Jenkins

Install Jenkins and start the service using Homebrew.

```shell
brew install jenkins
brew services start jenkins
```

## Configure GitLab

GitLab does not allow requests to localhost or the local network by default. When running Jenkins on your local machine, you need to enable local access.

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Outbound requests**, and select the following checkboxes:

   - **Allow requests to the local network from webhooks and integrations**
   - **Allow requests to the local network from system hooks**

  For more details about GitLab webhooks, see [Webhooks and insecure internal web services](../../security/webhooks.md).

Jenkins uses the GitLab API and needs an access token.

1. Sign in to your GitLab instance.
1. Select your profile picture, then select **Settings**.
1. Select **Access tokens**.
1. Create a new Access Token with the **API** scope enabled. Note the value of the token.

## Configure Jenkins

To configure your GitLab API connection in Jenkins, read
[Configure the Jenkins server](../../integration/jenkins.md#configure-the-jenkins-server).

## Configure Jenkins Project

To set up the Jenkins project you intend to run your build on, read
[Configure the Jenkins project](../../integration/jenkins.md#configure-the-jenkins-project).

## Configure your GitLab project

You can configure your integration between Jenkins and GitLab:

- With the [recommended approach for Jenkins integration](../../integration/jenkins.md#with-a-jenkins-server-url).
- [Using a webhook](../../integration/jenkins.md#with-a-webhook).

## Test your setup

Make a change in your repository and open an MR. In your Jenkins project it should have triggered a new build and on your MR, there should be a widget saying **Pipeline #NUMBER passed**.
It should also include a link to your Jenkins build.
