# Introduction to environments and deployments

>**Note:**
Introduced in GitLab 8.9.

## Environments

Environments are places where code gets deployed, such as staging or production.
CI/CD [Pipelines] usually have one or more [jobs] that deploy to an environment.
Defining environments in a project's `.gitlab-ci.yml` lets developers track
[deployments] to these environments.

## Deployments

Deployments are created when [jobs] deploy versions of code to [environments].

### Checkout deployments locally

Since 8.13, a reference in the git repository is saved for each deployment. So
knowing what the state is of your current environments is only a `git fetch`
away.

In your git config, append the `[remote "<your-remote>"]` block with an extra
fetch line:

```
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## Defining environments

You can create and delete environments manually in the web interface, but we
recommend that you define your environments in `.gitlab-ci.yml` first, which
will automatically create environments for you after the first deploy.

The `environment` is just a hint for GitLab that this job actually deploys to
this environment. Each time the job succeeds, a deployment is recorded,
remembering the git SHA and environment.

Add something like this to your `.gitlab-ci.yml`:
```
production:
  stage: deploy
  script: dpl...
  environment: production
```

See full [documentation](yaml/README.md#environment).

## Seeing environment status

You can find the environment list under **Pipelines > Environments** for your
project. You'll see the git SHA and date of the last deployment to each
environment defined.

>**Note:**
Only deploys that happen after your `.gitlab-ci.yml` is properly configured will
show up in the environments and deployments lists.

## Seeing deployment history

Clicking on an environment will show the history of deployments.

>**Note:**
Only deploys that happen after your `.gitlab-ci.yml` is properly configured will
show up in the environments and deployments lists.

[Pipelines]: pipelines.md
[jobs]: yaml/README.md#jobs
[environments]: #environments
[deployments]: #deployments
