# Jenkins CI (deprecated) service

>**Note:** In GitLab 8.3, Jenkins integration using the
[GitLab Hook Plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitLab+Hook+Plugin)
was deprecated in favor of the
[GitLab Plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitLab+Plugin).
Please use documentation for the new [Jenkins CI service](jenkins.md).

Integration includes:

* Trigger Jenkins build after push to repo
* Show build status on Merge Request page

Requirements:

* [Jenkins GitLab Hook plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitLab+Hook+Plugin)
* git clone access for Jenkins from GitLab repo (via ssh key)

## Jenkins

1. Install [GitLab Hook plugin](https://wiki.jenkins-ci.org/display/JENKINS/GitLab+Hook+Plugin)
2. Setup jenkins project

![screen](jenkins_project.png)

## GitLab

In GitLab, perform the following steps.

### Read access to repository

Jenkins needs read access to the GitLab repository. We already specified a
private key to use in Jenkins, now we need to add a public one to the GitLab
project. For that case we will need a Deploy key. Read the documentation on
[how to setup a Deploy key](../ssh/README.md#deploy-keys).

### Jenkins service

Now navigate to GitLab services page and activate Jenkins

![screen](jenkins_gitlab_service.png)

Done! Now when you push to GitLab - it will create a build for Jenkins.
And also you will be able to see merge request build status with a link to the Jenkins build.

### Multi-project Configuration

The GitLab Hook plugin in Jenkins supports the automatic creation of a project
for each feature branch. After configuration GitLab will trigger feature branch
builds and a corresponding project will be created in Jenkins.

Configure the GitLab Hook plugin in Jenkins. Go to 'Manage Jenkins' and then
'Configure System'. Find the 'GitLab Web Hook' section and configure as shown below.
