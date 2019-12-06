---
type: reference
---

# Environments and deployments

> Introduced in GitLab 8.9.

Environments allow control of the continuous deployment of your software,
all within GitLab.

## Introduction

There are many stages required in the software development process before the software is ready
for public consumption.

For example:

1. Develop your code.
1. Test your code.
1. Deploy your code into a testing or staging environment before you release it to the public.

This helps find bugs in your software, and also in the deployment process as well.

GitLab CI/CD is capable of not only testing or building your projects, but also
deploying them in your infrastructure, with the added benefit of giving you a
way to track your deployments. In other words, you will always know what is
currently being deployed or has been deployed on your servers.

It's important to know that:

- Environments are like tags for your CI jobs, describing where code gets deployed.
- Deployments are created when [jobs](yaml/README.md#introduction) deploy versions of code to environments,
  so every environment can have one or more deployments.

GitLab:

- Provides a full history of your deployments for each environment.
- Keeps track of your deployments, so you always know what is currently being deployed on your
  servers.

If you have a deployment service such as [Kubernetes](../user/project/clusters/index.md)
associated with your project, you can use it to assist with your deployments, and
can even access a [web terminal](#web-terminals) for your environment from within GitLab!

## Configuring environments

Configuring environments involves:

1. Understanding how [pipelines](pipelines.md) work.
1. Defining environments in your project's [`.gitlab-ci.yml`](yaml/README.md) file.
1. Creating a job configured to deploy your application. For example, a deploy job configured with [`environment`](yaml/README.md#environment) to deploy your application to a [Kubernetes cluster](../user/project/clusters/index.md).

The rest of this section illustrates how to configure environments and deployments using
an example scenario. It assumes you have already:

- Created a [project](../gitlab-basics/create-project.md) in GitLab.
- Set up [a Runner](runners/README.md).

In the scenario:

- We are developing an application.
- We want to run tests and build our app on all branches.
- Our default branch is `master`.
- We deploy the app only when a pipeline on `master` branch is run.

### Defining environments

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

We have defined three [stages](yaml/README.md#stages):

- `test`
- `build`
- `deploy`

The jobs assigned to these stages will run in this order. If any job fails, then
the pipeline fails and jobs that are assigned to the next stage won't run.

In our case:

- The `test` job will run first.
- Then the `build` job.
- Lastly the `deploy_staging` job.

With this configuration, we:

- Check that the tests pass.
- Ensure that our app is able to be built successfully.
- Lastly we deploy to the staging server.

NOTE: **Note:**
The `environment` keyword is just a hint for GitLab that this job actually
deploys to the `name` environment. It can also have a `url` that is
exposed in various places within GitLab. Each time a job that
has an environment specified succeeds, a deployment is recorded, storing
the Git SHA and environment name.

In summary, with the above `.gitlab-ci.yml` we have achieved the following:

- All branches will run the `test` and `build` jobs.
- The `deploy_staging` job will run [only](yaml/README.md#onlyexcept-basic) on the `master`
  branch, which means all merge requests that are created from branches don't
  get deployed to the staging server.
- When a merge request is merged, all jobs will run and the `deploy_staging`
  job will deploy our code to a staging server while the deployment
  will be recorded in an environment named `staging`.

#### Environment variables and Runner

Starting with GitLab 8.15, the environment name is exposed to the Runner in
two forms:

- `$CI_ENVIRONMENT_NAME`. The name given in `.gitlab-ci.yml` (with any variables
  expanded).
- `$CI_ENVIRONMENT_SLUG`. A "cleaned-up" version of the name, suitable for use in URLs,
  DNS, etc.

If you change the name of an existing environment, the:

- `$CI_ENVIRONMENT_NAME` variable will be updated with the new environment name.
- `$CI_ENVIRONMENT_SLUG` variable will remain unchanged to prevent unintended side
  effects.

Starting with GitLab 9.3, the environment URL is exposed to the Runner via
`$CI_ENVIRONMENT_URL`. The URL is expanded from either:

- `.gitlab-ci.yml`.
- The external URL from the environment if not defined in `.gitlab-ci.yml`.

### Configuring manual deployments

Adding `when: manual` to an automatically executed job's configuration converts it to
a job requiring manual action.

To expand on the [previous example](#defining-environments), the following includes
another job that deploys our app to a production server and is
tracked by a `production` environment.

The `.gitlab-ci.yml` file for this is as follows:

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

deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
  - master
```

The `when: manual` action:

- Exposes a "play" button in GitLab's UI for that job.
- Means the `deploy_prod` job will only be triggered when the "play" button is clicked.

You can find the "play" button in the pipelines, environments, deployments, and jobs views.

| View            | Screenshot                                                                     |
|:----------------|:-------------------------------------------------------------------------------|
| Pipelines       | ![Pipelines manual action](img/environments_manual_action_pipelines.png)       |
| Single pipeline | ![Pipelines manual action](img/environments_manual_action_single_pipeline.png) |
| Environments    | ![Environments manual action](img/environments_manual_action_environments.png) |
| Deployments     | ![Deployments manual action](img/environments_manual_action_deployments.png)   |
| Jobs            | ![Builds manual action](img/environments_manual_action_jobs.png)               |

Clicking on the play button in any view will trigger the `deploy_prod` job, and the
deployment will be recorded as a new environment named `production`.

NOTE: **Note:**
If your environment's name is `production` (all lowercase),
it will get recorded in [Cycle Analytics](../user/project/cycle_analytics.md).

### Configuring dynamic environments

Regular environments are good when deploying to "stable" environments like staging or production.

However, for environments for branches other than `master`, dynamic environments
can be used. Dynamic environments make it possible to create environments on the fly by
declaring their names dynamically in `.gitlab-ci.yml`.

Dynamic environments are a fundamental part of [Review apps](review_apps/index.md).

#### Allowed variables

The `name` and `url` parameters for dynamic environments can use most available CI/CD variables,
including:

- [Predefined environment variables](variables/README.md#predefined-environment-variables)
- [Project and group variables](variables/README.md#gitlab-cicd-environment-variables)
- [`.gitlab-ci.yml` variables](yaml/README.md#variables)

However, you cannot use variables defined:

- Under `script`.
- On the Runner's side.

There are also other variables that are unsupported in the context of `environment:name`.
For more information, see [Where variables can be used](variables/where_variables_can_be_used.md).

#### Example configuration

GitLab Runner exposes various [environment variables](variables/README.md) when a job runs, so
you can use them as environment names.

In the following example, the job will deploy to all branches except `master`:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - master
```

In this example:

- The job's name is `deploy_review` and it runs on the `deploy` stage.
- We set the `environment` with the `environment:name` as `review/$CI_COMMIT_REF_NAME`.
  Since the [environment name](yaml/README.md#environmentname) can contain slashes (`/`), we can
  use this pattern to distinguish between dynamic and regular environments.
- We tell the job to run [`only`](yaml/README.md#onlyexcept-basic) on branches,
  [`except`](yaml/README.md#onlyexcept-basic) `master`.

For the value of:

- `environment:name`, the first part is `review`, followed by a `/` and then `$CI_COMMIT_REF_NAME`,
  which receives the value of the branch name.
- `environment:url`, we want a specific and distinct URL for each branch. `$CI_COMMIT_REF_NAME`
  may contain a `/` or other characters that would be invalid in a domain name or URL,
  so we use `$CI_ENVIRONMENT_SLUG` to guarantee that we get a valid URL.

  For example, given a `$CI_COMMIT_REF_NAME` of `100-Do-The-Thing`, the URL will be something
  like `https://100-do-the-4f99a2.example.com`. Again, the way you set up
  the web server to serve these requests is based on your setup.

  We have used `$CI_ENVIRONMENT_SLUG` here because it is guaranteed to be unique. If
  you're using a workflow like [GitLab Flow](../topics/gitlab_flow.md), collisions
  are unlikely and you may prefer environment names to be more closely based on the
  branch name. In that case, you could use `$CI_COMMIT_REF_NAME` in `environment:url` in
  the example above: `https://$CI_COMMIT_REF_NAME.example.com`, which would give a URL
  of `https://100-do-the-thing.example.com`.

NOTE: **Note:**
You are not required to use the same prefix or only slashes (`/`) in the dynamic environments'
names. However, using this format will enable the [grouping similar environments](#grouping-similar-environments)
feature.

### Configuring Kubernetes deployments

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/27630) in GitLab 12.6.

If you are deploying to a [Kubernetes cluster](../user/project/clusters/index.md)
associated with your project, you can configure these deployments from your
`gitlab-ci.yml` file.

The following configuration options are supported:

- [`namespace`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

In the following example, the job will deploy your application to the
`production` Kubernetes namespace.

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
    kubernetes:
      namespace: production
  only:
  - master
```

NOTE: **Note:**
Kubernetes configuration is not supported for Kubernetes clusters
that are [managed by GitLab](../user/project/clusters/index.md#gitlab-managed-clusters).
To follow progress on support for Gitlab-managed clusters, see the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/issues/38054).

### Complete example

The configuration in this section provides a full development workflow where your app is:

- Tested.
- Built.
- Deployed as a Review App.
- Deployed to a staging server once the merge request is merged.
- Finally, able to be manually deployed to the production server.

The following combines the previous configuration examples, including:

- Defining [simple environments](#defining-environments) for testing, building, and deployment to staging.
- Adding [manual actions](#configuring-manual-deployments) for deployment to production.
- Creating [dynamic environments](#configuring-dynamic-environments) for deployments for reviewing.

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

deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - master

deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  environment:
    name: staging
    url: https://staging.example.com
  only:
  - master

deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
  - master
```

A more realistic example would also include copying files to a location where a
webserver (for example, NGINX) could then access and serve them.

The example below will copy the `public` directory to `/srv/nginx/$CI_COMMIT_REF_SLUG/public`:

```yaml
review_app:
  stage: deploy
  script:
    - rsync -av --delete public /srv/nginx/$CI_COMMIT_REF_SLUG
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_COMMIT_REF_SLUG.example.com
```

This example requires that NGINX and GitLab Runner are set up on the server this job will run on.

NOTE: **Note:**
See the [limitations](#limitations) section for some edge cases regarding the naming of
your branches and Review Apps.

The complete example provides the following workflow to developers:

- Create a branch locally.
- Make changes and commit them.
- Push the branch to GitLab.
- Create a merge request.

Behind the scenes, GitLab Runner will:

- Pick up the changes and start running the jobs.
- Run the jobs sequentially as defined in `stages`:
  - First, run the tests.
  - If the tests succeed, build the app.
  - If the build succeeds, the app is deployed to an environment with a name specific to the
    branch.

So now, every branch:

- Gets its own environment.
- Is deployed to its own unique location, with the added benefit of:
  - Having a [history of deployments](#viewing-deployment-history).
  - Being able to [rollback changes](#retrying-and-rolling-back) if needed.

For more information, see [Using the environment URL](#using-the-environment-url).

### Protected environments

Environments can be "protected", restricting access to them.

For more information, see [Protected environments](environments/protected_environments.md).

## Working with environments

Once environments are configured, GitLab provides many features for working with them,
as documented below.

### Viewing environments and deployments

A list of environments and deployment statuses is available on each project's **Operations > Environments** page.

For example:

![Environment view](img/environments_available.png)

This example shows:

- The environment's name with a link to its deployments.
- The last deployment ID number and who performed it.
- The job ID of the last deployment with its respective job name.
- The commit information of the last deployment, such as who committed it, to what
  branch, and the Git SHA of the commit.
- The exact time the last deployment was performed.
- A button that takes you to the URL that you defined under the `environment` keyword
  in `.gitlab-ci.yml`.
- A button that re-deploys the latest deployment, meaning it runs the job
  defined by the environment name for that specific commit.

The information shown in the **Environments** page is limited to the latest
deployments, but an environment can have multiple deployments.

> **Notes:**
>
> - While you can create environments manually in the web interface, we recommend
>   that you define your environments in `.gitlab-ci.yml` first. They will
>   be automatically created for you after the first deploy.
> - The environments page can only be viewed by users with [Reporter permission](../user/permissions.md#project-members-permissions)
>   and above. For more information on permissions, see the [permissions documentation](../user/permissions.md).
> - Only deploys that happen after your `.gitlab-ci.yml` is properly configured
>   will show up in the **Environment** and **Last deployment** lists.

### Viewing deployment history

GitLab keeps track of your deployments, so you:

- Always know what is currently being deployed on your servers.
- Can have the full history of your deployments for every environment.

Clicking on an environment shows the history of its deployments. Here's an example **Environments** page
with multiple deployments:

![Deployments](img/deployments_view.png)

This view is similar to the **Environments** page, but all deployments are shown. Also in this view
is a **Rollback** button. For more information, see [Retrying and rolling back](#retrying-and-rolling-back).

### Retrying and rolling back

If there is a problem with a deployment, you can retry it or roll it back.

To retry or rollback a deployment:

1. Navigate to **Operations > Environments**.
1. Click on the environment.
1. In the deployment history list for the environment, click the:
   - **Retry** button next to the last deployment, to retry that deployment.
   - **Rollback** button next to a previously successful deployment, to roll back to that deployment.

#### What to expect with a rollback

Pressing the **Rollback** button on a specific commit will trigger a _new_ deployment with its
own unique job ID.

This means that you will see a new deployment that points to the commit you are rolling back to.

NOTE: **Note:**
The defined deployment process in the job's `script` determines whether the rollback succeeds or not.

### Using the environment URL

The [environment URL](yaml/README.md#environmenturl) is exposed in a few
places within GitLab:

- In a merge request widget as a link:
  ![Environment URL in merge request](img/environments_mr_review_app.png)
- In the Environments view as a button:
  ![Environment URL in environments](img/environments_available.png)
- In the Deployments view as a button:
  ![Environment URL in deployments](img/deployments_view.png)

You can see this information in a merge request itself if:

- The merge request is eventually merged to the default branch (usually `master`).
- That branch also deploys to an environment (for example, `staging` or `production`).

For example:

![Environment URLs in merge request](img/environments_link_url_mr.png)

#### Going from source files to public pages

With GitLab's [Route Maps](review_apps/index.md#route-maps) you can go directly
from source files to public pages in the environment set for Review Apps.

### Stopping an environment

Stopping an environment:

- Moves it from the list of **Available** environments to the list of **Stopped**
  environments on the [**Environments** page](#viewing-environments-and-deployments).
- Executes an [`on_stop` action](yaml/README.md#environmenton_stop), if defined.

This is often used when multiple developers are working on a project at the same time,
each of them pushing to their own branches, causing many dynamic environments to be created.

NOTE: **Note:**
Starting with GitLab 8.14, dynamic environments are stopped automatically
when their associated branch is deleted.

#### Automatically stopping an environment

Environments can be stopped automatically using special configuration.

Consider the following example where the `deploy_review` job calls `stop_review`
to clean up and stop the environment:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review
  only:
    - branches
  except:
    - master

stop_review:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script:
    - echo "Remove review app"
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_NAME
    action: stop
```

Setting the [`GIT_STRATEGY`](yaml/README.md#git-strategy) to `none` is necessary in the
`stop_review` job so that the [GitLab Runner](https://docs.gitlab.com/runner/) won't
try to check out the code after the branch is deleted.

When you have an environment that has a stop action defined (typically when
the environment describes a Review App), GitLab will automatically trigger a
stop action when the associated branch is deleted. The `stop_review` job must
be in the same `stage` as the `deploy_review` job in order for the environment
to automatically stop.

You can read more in the [`.gitlab-ci.yml` reference](yaml/README.md#environmenton_stop).

### Grouping similar environments

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/7015) in GitLab 8.14.

As documented in [Configuring dynamic environments](#configuring-dynamic-environments), you can
prepend environment name with a word, followed by a `/`, and finally the branch
name, which is automatically defined by the `CI_COMMIT_REF_NAME` variable.

In short, environments that are named like `type/foo` are all presented under the same
group, named `type`.

In our [minimal example](#example-configuration), we named the environments `review/$CI_COMMIT_REF_NAME`
where `$CI_COMMIT_REF_NAME` is the branch name. Here is a snippet of the example:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
```

In this case, if you visit the **Environments** page and the branches
exist, you should see something like:

![Environment groups](img/environments_dynamic_groups.png)

### Monitoring environments

If you have enabled [Prometheus for monitoring system and response metrics](../user/project/integrations/prometheus.md),
you can monitor the behavior of your app running in each environment. For the monitoring
dashboard to appear, you need to Configure Prometheus to collect at least one
[supported metric](../user/project/integrations/prometheus_library/index.md).

NOTE: **Note:**
Since GitLab 9.2, all deployments to an environment are shown directly on the monitoring dashboard.

Once configured, GitLab will attempt to retrieve [supported performance metrics](../user/project/integrations/prometheus_library/index.md)
for any environment that has had a successful deployment. If monitoring data was
successfully retrieved, a **Monitoring** button will appear for each environment.

![Environment Detail with Metrics](img/deployments_view.png)

Clicking on the **Monitoring** button will display a new page showing up to the last
8 hours of performance data. It may take a minute or two for data to appear
after initial deployment.

All deployments to an environment are shown directly on the monitoring dashboard,
which allows easy correlation between any changes in performance and new
versions of the app, all without leaving GitLab.

![Monitoring dashboard](img/environments_monitoring.png)

#### Linking to external dashboard

Add a [button to the Monitoring dashboard](../user/project/operations/linking_to_an_external_dashboard.md) linking directly to your existing external dashboards.

#### Embedding metrics in GitLab Flavored Markdown

Metric charts can be embedded within GitLab Flavored Markdown. See [Embedding Metrics within GitLab Flavored Markdown](../user/project/integrations/prometheus.md#embedding-metric-charts-within-gitlab-flavored-markdown) for more details.

### Web terminals

> Web terminals were added in GitLab 8.15 and are only available to project Maintainers and Owners.

If you deploy to your environments with the help of a deployment service (for example,
the [Kubernetes integration](../user/project/clusters/index.md)), GitLab can open
a terminal session to your environment.

This is a powerful feature that allows you to debug issues without leaving the comfort
of your web browser. To enable it, just follow the instructions given in the service integration
documentation.

Once enabled, your environments will gain a "terminal" button:

![Terminal button on environment index](img/environments_terminal_button_on_index.png)

You can also access the terminal button from the page for a specific environment:

![Terminal button for an environment](img/environments_terminal_button_on_show.png)

Wherever you find it, clicking the button will take you to a separate page to
establish the terminal session:

![Terminal page](img/environments_terminal_page.png)

This works just like any other terminal. You'll be in the container created
by your deployment so you can:

- Run shell commands and get responses in real time.
- Check the logs.
- Try out configuration or code tweaks etc.

You can open multiple terminals to the same environment, they each get their own shell
session and even a multiplexer like `screen` or `tmux`.

NOTE: **Note:**
Container-based deployments often lack basic tools (like an editor), and may
be stopped or restarted at any time. If this happens, you will lose all your
changes. Treat this as a debugging tool, not a comprehensive online IDE.

### Check out deployments locally

Since GitLab 8.13, a reference in the Git repository is saved for each deployment, so
knowing the state of your current environments is only a `git fetch` away.

In your Git configuration, append the `[remote "<your-remote>"]` block with an extra
fetch line:

```text
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

### Scoping environments with specs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/2112) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.4.
> - [Scoping for environment variables was moved to Core](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/30779) to Core in GitLab 12.2.

You can limit the environment scope of a variable by
defining which environments it can be available for.

Wildcards can be used, and the default environment scope is `*`, which means
any jobs will have this variable, not matter if an environment is defined or
not.

For example, if the environment scope is `production`, then only the jobs
having the environment `production` defined would have this specific variable.
Wildcards (`*`) can be used along with the environment name, therefore if the
environment scope is `review/*` then any jobs with environment names starting
with `review/` would have that particular variable.

Some GitLab features can behave differently for each environment.
For example, you can
[create a secret variable to be injected only into a production environment](variables/README.md#limiting-environment-scopes-of-environment-variables).

In most cases, these features use the _environment specs_ mechanism, which offers
an efficient way to implement scoping within each environment group.

Let's say there are four environments:

- `production`
- `staging`
- `review/feature-1`
- `review/feature-2`

Each environment can be matched with the following environment spec:

| Environment Spec | `production` | `staging` | `review/feature-1` | `review/feature-2` |
|:-----------------|:-------------|:----------|:-------------------|:-------------------|
| *                | Matched      | Matched   | Matched            | Matched            |
| production       | Matched      |           |                    |                    |
| staging          |              | Matched   |                    |                    |
| review/*         |              |           | Matched            | Matched            |
| review/feature-1 |              |           | Matched            |                    |

As you can see, you can use specific matching for selecting a particular environment,
and also use wildcard matching (`*`) for selecting a particular environment group,
such as [Review Apps](review_apps/index.md) (`review/*`).

NOTE: **Note:**
The most _specific_ spec takes precedence over the other wildcard matching.
In this case, `review/feature-1` spec takes precedence over `review/*` and `*` specs.

### Environments Dashboard **(PREMIUM)**

See [Environments Dashboard](environments/environments_dashboard.md) for a summary of each
environment's operational health.

## Limitations

In the `environment: name`, you are limited to only the [predefined environment variables](variables/predefined_variables.md).
Re-using variables defined inside `script` as part of the environment name will not work.

## Further reading

Below are some links you may find interesting:

- [The `.gitlab-ci.yml` definition of environments](yaml/README.md#environment)
- [A blog post on Deployments & Environments](https://about.gitlab.com/blog/2016/08/26/ci-deployment-and-environments/)
- [Review Apps - Use dynamic environments to deploy your code for every branch](review_apps/index.md)
- [Deploy Boards for your applications running on Kubernetes](../user/project/deploy_boards.md) **(PREMIUM)**

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
