---
comments: false
type: index, howto
---

# Migrating from Jenkins

A lot of GitLab users have successfully migrated to GitLab CI/CD from Jenkins. To make this
easier if you're just getting started, we've collected several resources here that you might find useful
before diving in.

First of all, our [Quick Start Guide](../quick_start/README.md) contains a good overview of how GitLab CI/CD works.
You may also be interested in [Auto DevOps](../../topics/autodevops/index.md) which can potentially be used to build, test,
and deploy your applications with little to no configuration needed at all.

Otherwise, read on for important information that will help you get the ball rolling. Welcome
to GitLab!

## Important differences

There are some high level differences between the products worth mentioning:

- With GitLab you don't need a root `pipeline` keyword to wrap everything.
- All jobs within a single stage always run in parallel, and all stages run in sequence. We are planning
  to allow certain jobs to break this sequencing as needed with our [directed acyclic graph](https://gitlab.com/gitlab-org/gitlab-foss/issues/47063)
  feature.
- The `.gitlab-ci.yml` file is checked in to the root of your repository, much like a Jenkinsfile, but
  is in the YAML format (see [complete reference](../yaml/README.md)) instead of a Groovy DSL. It's most
  analagous to the declarative Jenkinsfile format.
- GitLab comes with a [container registry](../../user/packages/container_registry/index.md), and we recommend using
  container images to set up your build environment.

## Groovy vs. YAML

Jenkins Pipelines are based on [Groovy](https://groovy-lang.org/), so the pipeline specification is written as code.
GitLab works a bit differently, we use the more highly structured [YAML](https://yaml.org/) format, which
places scripting elements inside of `script:` blocks separate from the pipeline specification itself.

This is a strength of GitLab, in that it helps keep the learning curve much simpler to get up and running
and avoids some of the problem of unconstrained complexity which can make your Jenkinsfiles hard to understand
and manage.

That said, we do of course still value DRY (don't repeat yourself) principles and want to ensure that
behaviors of your jobs can be codified once and applied as needed. You can use the `extends:` syntax to
[templatize your jobs](../yaml/README.md#extends), and `include:` can be used to [bring in entire sets of behaviors](../yaml/README.md#include)
to pipelines in different projects.

```yaml
.in-docker:
  tags:
    - docker
  image: alpine

rspec:
  extends:
    - .in-docker
  script:
    - rake rspec
```

## Artifact publishing

Artifacts may work a bit differently than you've used them with Jenkins. In GitLab, any job can define
a set of artifacts to be saved by using the `artifacts:` keyword. This can be configured to point to a file
or set of files that can then be persisted from job to job. Read more on our detailed [artifacts documentation](../../user/project/pipelines/job_artifacts.html)

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
    - ./mycv.pdf
    - ./output/
    expire_in: 1 week
```

Additionally, we have package management features like a built-in container, NPM, and Maven registry that you
can leverage. You can see the complete list of packaging features (which includes links to documentation)
in the [Packaging section of our documentation](../../README.md#package).

## Integrated features

Where you may have used plugins to get things like code quality, unit tests, security scanning, and so on working in Jenkins,
GitLab takes advantage of our connected ecosystem to automatically pull these kinds of results into
your Merge Requests, pipeline details pages, and other locations. You may find that you actually don't
need to configure anything to have these appear.

If they aren't working as expected, or if you'd like to see what's available, our [CI feature index](../README.md#feature-set) has the full list
of bundled features and links to the documentation for each.

## Converting Declarative Jenkinsfiles

Declarative Jenkinsfiles contain "Sections" and "Directives" which are used to control the behavior of your
pipelines. There are equivalents for all of these in GitLab, which we've documented below.

This section is based on the [Jenkinsfile syntax documentation](https://jenkins.io/doc/book/pipeline/syntax/)
and is meant to be a mapping of concepts there to concepts in GitLab.

### Sections

#### `agent`

The agent section is used to define how a pipeline will be executed. For GitLab, we use the [GitLab Runner](../runners/README.md)
to provide this capability. You can configure your own runners in Kubernetes or on any host, or take advantage
of our shared runner fleet (note that the shared runner fleet is only available for GitLab.com users.) The link above will bring you to the documenation which will describe how to get
up and running quickly. We also support using [tags](../runners/README.md#using-tags) to direct different jobs
to different Runners (execution agents).

The `agent` section also allows you to define which Docker images should be used for execution, for which we use
the [`image`](../yaml/README.md#image) keyword. The `image` can be set on a single job or at the top level, in which
case it will apply to all jobs in the pipeline.

```yaml
my_job:
  image: alpine
  ...
```

#### `post`

The `post` section defines the actions that should be performed at the end of the pipeline. GitLab also supports
this through the use of stages. You can define your stages as follows, and any jobs assigned to the `before_pipeline`
or `after_pipeline` stages will run as expected. You can call these stages anything you like.

```yaml
stages:
  - before_pipeline
  - build
  - test
  - deploy
  - after_pipeline
```  

Setting a step to be performed before and after any job can be done via the [`before_script` and `after_script` keywords](../yaml/README.md#before_script-and-after_script).

```yaml
default:
  before_script:
    - echo "I run before any jobs starts in the entire pipeline, and can be responsible for setting up the environment."
```

#### `stages`

GitLab CI also lets you define stages, but is a little bit more free-form to configure. The GitLab [`stages` keyword](../yaml/README.md#stages)
is a top level setting that enumerates the list of stages, but you are not required to nest individual jobs underneath
the `stages` section. Any job defined in the `.gitlab-ci.yml` can be made a part of any stage through use of the
[`stage:` keyword](../yaml/README.md#stage).

Note that, unless otherwise specified, every pipeline is instantiated with a `build`, `test`, and `deploy` stage
which are run in that order. Jobs that have no `stage` defined are placed by default in the `test` stage.
Of course, each job that refers to a stage must refer to a stage that exists in the pipeline configuration.

```yaml
stages:
  - build
  - test
  - deploy

my_job:
  stage: build
  ...
```

#### `steps`

The `steps` section is equivalent to the [`script` section](../yaml/README.md#script) of an individual job. This is
a simple YAML array with each line representing an individual command to be run.

```yaml
my_job:
  script:
    - echo "hello! the current time is:"
    - time
  ...
```

### Directives

#### `environment`

In GitLab, we use the [`variables` keyword](../yaml/README.md#variables) to define different variables at runtime.
These can also be set up through the GitLab UI, under CI/CD settings. See also our [general documentation on variables](../variables/README.md),
including the section on [protected variables](../variables/README.md#protected-environment-variables) which can be used
to limit access to certain variables to certain environments or runners.

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
```

#### `options`

Here, options for different things exist associated with the object in question itself. For example, options related
to jobs are defined in relation to the job itself. If you're looking for a certain option, you should be able to find
where it's located by searching our [complete configuration reference](../yaml/README.md) page.

#### `parameters`

GitLab does not require you to define which variables you want to be available when starting a manual job. A user
can provide any variables they like.

#### `triggers` / `cron`

Because GitLab is integrated tightly with Git, SCM polling options for triggers are not needed. We support an easy to use
[syntax for scheduling pipelines](../../user/project/pipelines/schedules.md).

#### `tools`

GitLab does not support a separate `tools` directive. Our best-practice reccomendation is to use pre-built
container images, which can be cached, and can be built to already contain the tools you need for your pipelines. Pipelines can
be set up to automatically build these images as needed and deploy them to the [container registry](../../user/packages/container_registry/index.md).

If you're not using container images with Docker/Kubernetes, for example on Mac or FreeBSD, then the `shell` executor does require you to
set up your environment either in advance or as part of the jobs. You could create a `before_script`
action that handles this for you.

#### `input`

Similar to the `parameters` keyword, this is not needed because a manual job can always be provided runtime
variable entry.

#### `when`

GitLab does support a [`when` keyword](../yaml/README.md#when) which is used to indicate when a job should be
run in case of (or despite) failure, but most of the logic for controlling pipelines can be found in
our very powerful [`only/except` rules system](../yaml/README.md#onlyexcept-basic) (see also our [advanced syntax](../yaml/README.md#onlyexcept-basic))

```yaml
my_job:
  only: [branches]
```
