# Introduction to environments and deployments

>**Note:**
Introduced in GitLab 8.9.

During the development of software, there can be many stages until it's ready
for public consumption. You sure want to first test your code and then deploy it
in a testing or staging environment before you release it to the public. That
way you can prevent bugs not only in your software, but in the deployment
process as well.

GitLab CI is capable of not only testing or building your projects, but also
deploying them in your infrastructure, with the added benefit of giving you a
way to track your deployments. In other words, you can always know what is
currently being deployed or has been deployed on your servers.

## Overview

With environments, you can control the Continuous Deployment of your software
all within GitLab. All you need to do is define them in your project's
[`.gitlab-ci.yml`][yaml] as we will explore below. GitLab provides a full
history of your deployments per every environment.

Environments are like tags for your CI jobs, describing where code gets deployed.
Deployments are created when [jobs] deploy versions of code to environments,
so every environment can have one or more deployments. GitLab keeps track of
your deployments, so you always know what is currently being deployed on your
servers.

To better understand how environments and deployments work, let's consider an
example. We assume that you have already created a project in GitLab and set up
a Runner. The example will cover the following:

- We are developing an application
- We want to run tests and build our app on all branches
- Our default branch is `master`
- We deploy the app only when a pipeline on `master` branch is run

Let's see how it all ties together.

## Defining environments

Let's consider the following `.gitlab-ci.yml` example:

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  script: echo "Running tests"

build:
  stage: build
  script: echo "Building the app"

deploy_staging:
  stage: deploy
  script:
      - echo "Deploy to staging server"
  environment:
      name: staging
      url: https://staging.example.com
  only:
  - master
```

We have defined 3 [stages](yaml/README.md#stages):

- test
- build
- deploy

The jobs assigned to these stages will run in this order. If a job fails, then
the builds that are assigned to the next stage won't run, rendering the pipeline
as failed. In our case, the `test` job will run first, then the `build` and
lastly the `deploy_staging`. With this, we ensure that first the tests pass,
then our app is able to be built successfully, and lastly we deploy to the
staging server.

With the above `.gitlab-ci.yml` we have achieved that:

- All branches will run the `test` and `build` jobs.
- The `deploy_staging` job will [only](yaml/README.md#only) run on the `master`
  branch which means all merge requests
- When a merge request is merged, all jobs will run and the `deploy_staging`
  in particular will deploy our code to a staging server while the deployment
  will be recorded in an environment named `staging`.

The `environment` keyword is just a hint for GitLab that this job actually
deploys to this environment. Each time the job succeeds, a deployment is
recorded, remembering the Git SHA and environment name. Here's how the
Environments page looks so far.

![Staging environment view](img/environments_available_staging.png)

TODO: describe what the above page means

>**Notes:**
- While you can create environments manually in the web interface, we recommend
  that you define your environments in `.gitlab-ci.yml` first. They will
  be automatically created for you after the first deploy.
- The environments page can only be viewed by Reporters and above. For more
  information on the permissions, see the [permissions documentation][permissions].

As we've pointed in the Overview section, environments are like tags for your
CI jobs, describing where code gets deployed. Here's what happened behind the
scenes:

1. The jobs and environments were defined in `.gitlab-ci.yml`
1. Changes were pushed to the repository in GitLab
1. The Runner(s) picked up the jobs
1. The jobs finished successfully
1. The environments got created if they didn't already exist
1. A deployment was recorded remembering the environment name and the Git SHA of
   the last commit of the pipeline

## View the environment status

GitLab keeps track of your deployments, so you always know what is currently
being deployed on your servers. You can find the environment list under
**Pipelines > Environments** for your project. You'll see the git SHA and date
of the last deployment to each environment defined.

![Environments](img/environments_view.png)

>**Note:**
Only deploys that happen after your `.gitlab-ci.yml` is properly configured will
show up in the "Environment" and "Last deployment" lists.

## Manually deploying to environments

CI/CD [Pipelines] usually have one or more [jobs] that deploy to an environment.
You can think of names such as testing, staging or production.


## Dynamic environments

As the name suggests, it is possible to create environments on the fly by just
declaring their names dynamically in `.gitlab-ci.yml`.

GitLab Runner exposes various [environment variables][variables] when a job runs,
and as such you can use them

```
review:
  stage: deploy
  script:
    - rsync -av --delete public /srv/nginx/pages/$CI_BUILD_REF_NAME
  environment:
    name: review/$CI_BUILD_REF_NAME
    url: https://$CI_BUILD_REF_NAME.example.com
```

## Closing an environment

```
review:
  stage: deploy
  script:
    - rsync -av --delete public /srv/nginx/pages/$CI_BUILD_REF_NAME
  environment:
    name: review/$CI_BUILD_REF_NAME
    url: http://$CI_BUILD_REF_NAME.$APPS_DOMAIN
    on_stop: stop_review

stop_review:
  script: rm -rf /srv/nginx/pages/$CI_BUILD_REF_NAME
  when: manual
  environment:
    name: review/$CI_BUILD_REF_NAME
    action: stop
```

## View the deployment history

Clicking on an environment will show the history of deployments.

![Deployments](img/deployments_view.png)

>**Note:**
Only deploys that happen after your `.gitlab-ci.yml` is properly configured will
show up in the environments and deployments lists.

## Checkout deployments locally

Since 8.13, a reference in the git repository is saved for each deployment. So
knowing what the state is of your current environments is only a `git fetch`
away.

In your git config, append the `[remote "<your-remote>"]` block with an extra
fetch line:

```
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## Further reading

Below are some links you may find interesting:

- [The `.gitlab-ci.yml` definition of environments](yaml/README.md#environment)
- [A blog post on Deployments & Environments](https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/)
- [Review Apps](review_apps.md) Expand dynamic environments to deploy your code for every branch


## WIP

Actions

View environments
View deployments
  Rollback deployments
  Run deployments
View link to environment URL
View last commit message of deployment
View person who performed the deployment
View commit SHA that triggered the deployment
View branch the deployment was based on
View time ago the deployment was performed

[Pipelines]: pipelines.md
[jobs]: yaml/README.md#jobs
[yaml]: yaml/README.md
[environments]: #environments
[deployments]: #deployments
[permissions]: ../user/permissions.md
[variables]: variables/README.md
