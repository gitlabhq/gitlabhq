---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, howto
---

# Migrating from Jenkins **(FREE ALL)**

If you're migrating from Jenkins to GitLab CI/CD, you should be able
to create CI/CD pipelines that do everything you need.

You can start by watching the [Migrating from Jenkins to GitLab](https://www.youtube.com/watch?v=RlEVGOpYF5Y)
video for examples of:

- Converting a Jenkins pipeline into a GitLab CI/CD pipeline.
- Using Auto DevOps to test your code automatically.

## Get started

The following list of recommended steps was created after observing organizations
that were able to quickly complete this migration.

Before doing any migration work, you should [start with a migration plan](plan_a_migration.md).

Engineers that need to migrate projects to GitLab CI/CD should:

- Read about some [key GitLab CI/CD features](#key-gitlab-cicd-features).
- Follow tutorials to create:
  - [Your first GitLab pipeline](../quick_start/index.md).
  - [A more complex pipeline](../quick_start/tutorial.md) that builds, tests,
    and deploys a static site.
- Review the [`.gitlab-ci.yml` keyword reference](../yaml/index.md).
- Ensure [runners](../runners/index.md) are available, either by using shared GitLab.com runners
  or installing new runners.
- Migrate build and CI jobs and configure them to show results directly in merge requests.
  You can use [Auto DevOps](../../topics/autodevops/index.md) as a starting point,
  and [customize](../../topics/autodevops/customize.md) or [decompose](../../topics/autodevops/customize.md#use-individual-components-of-auto-devops)
  the configuration as needed.
- Migrate deployment jobs by using [cloud deployment templates](../cloud_deployment/index.md),
  [environments](../environments/index.md), and the [GitLab agent for Kubernetes](../../user/clusters/agent/index.md).
- Check if any CI/CD configuration can be reused across different projects, then create
  and share [templates](#templates).
- Check the [pipeline efficiency documentation](../pipelines/pipeline_efficiency.md)
  to learn how to make your GitLab CI/CD pipelines faster and more efficient.

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/)
can be a great resource.

### Key GitLab CI/CD features

GitLab CI/CD key features might be different or not exist in Jenkins. For example,
in GitLab:

- Pipelines can be triggered with:
  - A Git push
  - A [Schedule](../pipelines/schedules.md)
  - The [GitLab UI](../pipelines/index.md#run-a-pipeline-manually)
  - An [API call](../triggers/index.md)
  - A [webhook](../triggers/index.md#use-a-webhook)
- You can control which jobs run in which cases with the [`rules` syntax](../yaml/index.md#rules).
- You can reuse pipeline configurations:
  - Use the [`extends` keyword](../yaml/index.md#extends) to reuse configuration
    in a single pipeline configuration.
  - Use the [`include` keyword](../yaml/index.md#include) to reuse configuration across
    multiple pipelines and projects.
- Jobs are grouped into stages, and jobs in the same stage can run at the same time.
  Stages run in sequence. Jobs can be configured to run outside of the stage ordering with the
  [`needs` keyword](../yaml/index.md#needs).
- The [`parallel`](../yaml/index.md#parallel) keyword can automatically parallelize tasks,
  especially tests that support parallelization.
- Jobs run independently of each other and have a fresh environment for each job.
  Passing artifacts between jobs is controlled using the [`artifacts`](../yaml/index.md#artifacts)
  and [`dependencies`](../yaml/index.md#dependencies) keywords.
- The `.gitlab-ci.yml` configuration file exists in your Git repository, like a `Jenkinsfile`,
  but is [a YAML file](#yaml-configuration-file), not Groovy.
- GitLab comes with a [container registry](../../user/packages/container_registry/index.md).
  You can build and store custom container images to run your jobs in.

## Runners

Like Jenkins agents, GitLab runners are the hosts that run jobs. If you are using GitLab.com,
you can use the [shared runner fleet](../runners/index.md) to run jobs without provisioning
your own runners.

To convert a Jenkins agent for use with GitLab CI/CD, uninstall the agent and then
[install and register a runner](../runners/index.md). Runners do not require much overhead,
so you might be able to use similar provisioning as the Jenkins agents you were using.

Some key details about runners:

- Runners can be [configured](../runners/runners_scope.md) to be shared across an instance,
  a group, or dedicated to a single project.
- You can use the [`tags` keyword](../runners/configure_runners.md#use-tags-to-control-which-jobs-a-runner-can-run)
  for finer control, and associate runners with specific jobs. For example, you can use a tag for jobs that
  require dedicated, more powerful, or specific hardware.
- GitLab has [autoscaling for runners](https://docs.gitlab.com/runner/configuration/autoscale.html).
  Use autoscaling to provision runners only when needed and scale down when not needed,
  similar to ephemeral agents in Jenkins.

## YAML configuration file

GitLab pipeline configuration files use the [YAML](https://yaml.org/) format instead of
the [Groovy](https://groovy-lang.org/) format that Jenkins uses.

Using YAML is a strength of GitLab CI/CD, as it is a simple format to understand
and start using. For example, a small configuration file with two jobs and some
shared configuration in a hidden job:

```yaml
.test-config:
  tags:
    - docker-runners
  stage: test

test-job:
  extends:
    - .docker-config
  script:
    - bundle exec rake rspec

lint-job:
  extends:
    - .docker-config
  script:
    - yarn run prettier
```

In this example:

- The commands to run in jobs are added with the [`script` keyword](../yaml/index.md#script).
- The [`extends` keyword](../yaml/index.md#extends) reduces duplication in the configuration
  by adding the same `tags` and `stage` configuration defined in `.test-config` to both jobs.

### Artifacts

In GitLab, any job can use the [`artifacts` keyword](../yaml/index.md#artifacts)
to define a set of [artifacts](../jobs/job_artifacts.md) to be stored when a job completes.
Artifacts are files that can be used in later jobs, for example for testing or deployment.

For example:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
      - output/
    expire_in: 1 week
```

In this example:

- The `mycv.pdf` file and all the files in `output/` are stored and could be used
  in later jobs.
- To save resources, the artifacts expire and are deleted after one week.

### Scanning features

You might have used plugins for things like code quality, security, or static application scanning
in Jenkins. Tools like these are already available in GitLab and can be used in your
pipeline.

GitLab features including [code quality](../testing/code_quality.md), [security scanning](../../user/application_security/index.md),
[SAST](../../user/application_security/sast/index.md), and many others generate reports
when they complete. These reports can be displayed in merge requests and pipeline details pages.

### Templates

For organizations with many CI/CD pipelines, you can use project templates to configure
custom CI/CD configuration templates and reuse them across projects.

Group maintainers can configure a group to use as the source for [custom project templates](../../administration/custom_project_templates.md).
These templates can be used by all projects in the group.

An instance administrator can set a group as the source for [instance project templates](../../user/group/custom_project_templates.md),
which can be used by all projects in that instance.

## Convert a declarative Jenkinsfile

A declarative Jenkinsfile contains "Sections" and "Directives" which are used to control the behavior of your
pipelines. Equivalents for all of these exist in GitLab, which we've documented below.

This section is based on the [Jenkinsfile syntax documentation](https://www.jenkins.io/doc/book/pipeline/syntax/)
and is meant to be a mapping of concepts there to concepts in GitLab.

### Sections

#### `agent`

The agent section is used to define how a pipeline executes. For GitLab, we use [runners](../runners/index.md)
to provide this capability. You can configure your own runners in Kubernetes or on any host. You can also take advantage
of our shared runner fleet (the shared runner fleet is only available for GitLab.com users).
We also support using [tags](../runners/configure_runners.md#use-tags-to-control-which-jobs-a-runner-can-run) to direct different jobs
to different runners (execution agents).

The `agent` section also allows you to define which Docker images should be used for execution, for which we use
the [`image`](../yaml/index.md#image) keyword. The `image` can be set on a single job or at the top level, in which
case it applies to all jobs in the pipeline:

```yaml
my_job:
  image: alpine
```

#### `post`

The `post` section defines the actions that should be performed at the end of the pipeline. GitLab also supports
this through the use of stages. You can define your stages as follows, and any jobs assigned to the `before_pipeline`
or `after_pipeline` stages run as expected. You can call these stages anything you like:

```yaml
stages:
  - before_pipeline
  - build
  - test
  - deploy
  - after_pipeline
```

Setting a step to be performed before and after any job can be done via the
[`before_script`](../yaml/index.md#before_script) and [`after_script`](../yaml/index.md#after_script) keywords:

```yaml
default:
  before_script:
    - echo "I run before any jobs starts in the entire pipeline, and can be responsible for setting up the environment."
```

#### `stages`

GitLab CI/CD also lets you define stages, but is a little bit more free-form to configure. The GitLab [`stages` keyword](../yaml/index.md#stages)
is a top level setting that enumerates the list of stages. You are not required to nest individual jobs underneath
the `stages` section. Any job defined in the `.gitlab-ci.yml` can be made a part of any stage through use of the
[`stage` keyword](../yaml/index.md#stage).

Unless otherwise specified, every pipeline is instantiated with a `build`, `test`, and `deploy` stage
which are run in that order. Jobs that have no `stage` defined are placed by default in the `test` stage.
Of course, each job that refers to a stage must refer to a stage that exists in the pipeline configuration.

```yaml
stages:
  - build
  - test
  - deploy

my_job:
  stage: build
```

#### `steps`

The `steps` section is equivalent to the [`script` section](../yaml/index.md#script) of an individual job. The `steps` section is a YAML array
with each line representing an individual command to be run:

```yaml
my_job:
  script:
    - echo "hello! the current time is:"
    - time
```

### Directives

#### `environment`

In GitLab, we use the [`variables` keyword](../yaml/index.md#variables) to define different variables at runtime.
These can also be set up through the GitLab UI, under CI/CD settings. See also our [general documentation on variables](../variables/index.md),
including the section on [protected variables](../variables/index.md#protect-a-cicd-variable). This can be used
to limit access to certain variables to certain environments or runners:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
```

#### `options`

Here, options for different things exist associated with the object in question itself. For example, options related
to jobs are defined in relation to the job itself. If you're looking for a certain option, you should be able to find
where it's located by searching our [complete configuration reference](../yaml/index.md) page.

#### `parameters`

GitLab does not require you to define which variables you want to be available when starting a manual job. A user
can provide any variables they like.

#### `triggers` / `cron`

Because GitLab is integrated tightly with Git, SCM polling options for triggers are not needed. We support a
[syntax for scheduling pipelines](../pipelines/schedules.md).

#### `tools`

GitLab does not support a separate `tools` directive. Our best-practice recommendation is to use pre-built
container images. These images can be cached and can be built to already contain the tools you need for your pipelines. Pipelines can
be set up to automatically build these images as needed and deploy them to the [container registry](../../user/packages/container_registry/index.md).

If you don't use container images with Docker or Kubernetes, but use the `shell` executor on your own system,
you must set up your environment. You can set up the environment in advance, or as part of the jobs
with a `before_script` action that handles this for you.

#### `input`

Similar to the `parameters` keyword, this is not needed because a manual job can always be provided runtime
variable entry.

#### `when`

GitLab does support a [`when` keyword](../yaml/index.md#when) which is used to indicate when a job should be
run in case of (or despite) failure. Most of the logic for controlling pipelines can be found in
our very powerful [`rules` system](../yaml/index.md#rules):

```yaml
my_job:
  script:
    - echo
  rules:
    - if: $CI_COMMIT_BRANCH
```

## Secrets Management

Privileged information, often referred to as "secrets", is sensitive information
or credentials you need in your CI/CD workflow. You might use secrets to unlock protected resources
or sensitive information in tools, applications, containers, and cloud-native environments.

Secrets management in Jenkins is usually handled with the `Secret` type field or the
Credentials Plugin. Credentials stored in the Jenkins settings can be exposed to
jobs as environment variables by using the Credentials Binding plugin.

For secrets management in GitLab, you can use one of the supported integrations
for an external service. These services securely store secrets outside of your GitLab project,
though you must have a subscription for the service:

- [HashiCorp Vault](../secrets/id_token_authentication.md#automatic-id-token-authentication-with-hashicorp-vault)
- [Azure Key Vault](../secrets/azure_key_vault.md).

GitLab also supports [OIDC authentication](../secrets/id_token_authentication.md)
for other third party services that support OIDC.

Additionally, you can make credentials available to jobs by storing them in CI/CD variables, though secrets
stored in plain text are susceptible to accidental exposure, [the same as in Jenkins](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets).
You should always store sensitive information in [masked](../variables/index.md#mask-a-cicd-variable)
and [protected](../variables/index.md#protect-a-cicd-variable) variables, which mitigates
some of the risk.

Also, never store secrets as variables in your `.gitlab-ci.yml` file, which is public to all
users with access to the project. Storing sensitive information in variables should
only be done in [the project, group, or instance settings](../variables/index.md#define-a-cicd-variable-in-the-ui).

Review the [security guidelines](../variables/index.md#cicd-variable-security) to improve
the safety of your CI/CD variables.

## Additional resources

- You can use the [JenkinsFile Wrapper](https://gitlab.com/gitlab-org/jfr-container-builder/)
  to run a complete Jenkins instance inside of a GitLab CI/CD job, including plugins. Use this tool to
  help ease the transition to GitLab CI/CD, by delaying the migration of less urgent pipelines.

  NOTE:
  The JenkinsFile Wrapper is not packaged with GitLab and falls outside of the scope of support.
  For more information, see the [Statement of Support](https://about.gitlab.com/support/statement-of-support/).
- If your tooling outputs packages that you want to make accessible, you can store them
  in a [package registry](../../user/packages/index.md).
- Use [review Apps](../review_apps/index.md) to preview changes before merging them.
