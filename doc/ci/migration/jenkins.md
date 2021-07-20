---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
type: index, howto
---

# Migrating from Jenkins **(FREE)**

A lot of GitLab users have successfully migrated to GitLab CI/CD from Jenkins. To make this
easier if you're just getting started, we've collected several resources here that you might find useful
before diving in. Think of this page as a "GitLab CI/CD for Jenkins Users" guide.

The following list of recommended steps was created after observing organizations
that were able to quickly complete this migration:

1. Start by reading the GitLab CI/CD [Quick Start Guide](../quick_start/index.md) and [important product differences](#important-product-differences).
1. Learn the importance of [managing the organizational transition](#managing-the-organizational-transition).
1. [Add runners](../runners/index.md) to your GitLab instance.
1. Educate and enable your developers to independently perform the following steps in their projects:
   1. Review the [Quick Start Guide](../quick_start/index.md) and [Pipeline Configuration Reference](../yaml/index.md).
   1. Use the [Jenkins Wrapper](#jenkinsfile-wrapper) to temporarily maintain fragile Jenkins jobs.
   1. Migrate the build and CI jobs and configure them to show results directly in your merge requests. They can use [Auto DevOps](../../topics/autodevops/index.md) as a starting point, and [customize](../../topics/autodevops/customize.md) or [decompose](../../topics/autodevops/customize.md#using-components-of-auto-devops) the configuration as needed.
   1. Add [Review Apps](../review_apps/index.md).
   1. Migrate the deployment jobs using [cloud deployment templates](../cloud_deployment/index.md), adding [environments](../environments/index.md), and [deploy boards](../../user/project/deploy_boards.md).
   1. Work to unwrap any jobs still running with the use of the Jenkins wrapper.
1. Take stock of any common CI/CD job definitions then create and share [templates](#templates) for them.
1. Check the [pipeline efficiency documentation](../pipelines/pipeline_efficiency.md)
   to learn how to make your GitLab CI/CD pipelines faster and more efficient.

For an example of how to convert a Jenkins pipeline into a GitLab CI/CD pipeline,
or how to use Auto DevOps to test your code automatically, watch the
[Migrating from Jenkins to GitLab](https://www.youtube.com/watch?v=RlEVGOpYF5Y) video.

Otherwise, read on for important information that helps you get the ball rolling. Welcome
to GitLab!

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/)
can be a great resource.

## Managing the organizational transition

An important part of transitioning from Jenkins to GitLab is the cultural and organizational
changes that comes with the move, and successfully managing them. There are a few
things we have found that helps this:

- Setting and communicating a clear vision of what your migration goals are helps
  your users understand why the effort is worth it. The value is clear when
  the work is done, but people need to be aware while it's in progress too.
- Sponsorship and alignment from the relevant leadership team helps with the point above.
- Spending time educating your users on what's different, sharing this document with them,
  and so on helps ensure you are successful.
- Finding ways to sequence or delay parts of the migration can help a lot, but you
  don't want to leave things in a non-migrated (or partially-migrated) state for too
  long. To gain all the benefits of GitLab, moving your existing Jenkins setup over
  as-is, including any current problems, isn't enough. You need to take advantage
  of the improvements that GitLab offers, and this requires (eventually) updating
  your implementation as part of the transition.

## JenkinsFile Wrapper

We are building a [JenkinsFile Wrapper](https://gitlab.com/gitlab-org/jfr-container-builder/) which
you can use to run a complete Jenkins instance inside of a GitLab job, including plugins. This can help ease the process
of transition, by letting you delay the migration of less urgent pipelines for a period of time.

If you are interested in helping GitLab test the wrapper, join our [public testing issue](https://gitlab.com/gitlab-org/gitlab/-/issues/215675) for instructions and to provide your feedback.

## Important product differences

There are some high level differences between the products worth mentioning:

- With GitLab you don't need a root `pipeline` keyword to wrap everything.
- The way pipelines are triggered and [trigger other pipelines](../yaml/index.md#trigger)
  is different than Jenkins. GitLab pipelines can be triggered:

  - on push
  - on [schedule](../pipelines/schedules.md)
  - from the [GitLab UI](../pipelines/index.md#run-a-pipeline-manually)
  - by [API call](../triggers/index.md)
  - by [webhook](../triggers/index.md#triggering-a-pipeline-from-a-webhook)
  - by [ChatOps](../chatops/index.md)

- You can control which jobs run in which cases, depending on how they are triggered,
  with the [`rules` syntax](../yaml/index.md#rules).
- GitLab [pipeline scheduling concepts](../pipelines/schedules.md) are also different from Jenkins.
- You can reuse pipeline configurations using the [`include` keyword](../yaml/index.md#include)
  and [templates](#templates). Your templates can be kept in a central repository (with different
  permissions), and then any project can use them. This central project could also
  contain scripts or other reusable code.
- You can also use the [`extends` keyword](../yaml/index.md#extends) to reuse configuration
  within a single pipeline configuration.
- All jobs within a single stage always run in parallel, and all stages run in sequence. We are planning
  to allow certain jobs to break this sequencing as needed with our [directed acyclic graph](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47063)
  feature.
- The [`parallel`](../yaml/index.md#parallel) keyword can automatically parallelize tasks,
  like tests that support parallelization.
- Normally all jobs within a single stage run in parallel, and all stages run in sequence.
  There are different [pipeline architectures](../pipelines/pipeline_architectures.md)
  that allow you to change this behavior.
- The new [`rules` syntax](../yaml/index.md#rules) is the recommended method of
  controlling when different jobs run. It is more powerful than the `only/except` syntax.
- One important difference is that jobs run independently of each other and have a
  fresh environment in each job. Passing artifacts between jobs is controlled using the
  [`artifacts`](../yaml/index.md#artifacts) and [`dependencies`](../yaml/index.md#dependencies)
  keywords. When finished, use the planned [Workspaces](https://gitlab.com/gitlab-org/gitlab/-/issues/29265)
  feature to more easily persist a common workspace between serial jobs.
- The `.gitlab-ci.yml` file is checked in to the root of your repository, much like a Jenkinsfile, but
  is in the YAML format (see [complete reference](../yaml/index.md)) instead of a Groovy DSL. It's most
  analogous to the declarative Jenkinsfile format.
- Manual approvals or gates can be set up as [`when:manual` jobs](../yaml/index.md#whenmanual). These can
  also leverage [`protected environments`](../yaml/index.md#protecting-manual-jobs)
  to control who is able to approve them.
- GitLab comes with a [container registry](../../user/packages/container_registry/index.md), and we recommend using
  container images to set up your build environment. For example, set up one pipeline that builds your build environment
  itself and publish that to the container registry. Then, have your pipelines use this instead of each building their
  own environment, which is slower and may be less consistent. We have extensive docs on [how to use the Container Registry](../../user/packages/container_registry/index.md).
- A central utilities repository can be a great place to put assorted scheduled jobs
  or other manual jobs that function like utilities. Jenkins installations tend to
  have a few of these.

## Agents vs. runners

Both Jenkins agents and GitLab runners are the hosts that run jobs. To convert the
Jenkins agent, simply uninstall it and then [install and register the runner](../runners/index.md).
Runners do not require much overhead, so you can size them similarly to the Jenkins
agents you were using.

There are some important differences in the way runners work in comparison to agents:

- Runners can be set up as [shared across an instance, be added at the group level, or set up at the project level](../runners/runners_scope.md).
  They self-select jobs from the scopes you've defined automatically.
- You can also [use tags](../runners/configure_runners.md#use-tags-to-limit-the-number-of-jobs-using-the-runner) for finer control, and
  associate runners with specific jobs. For example, you can use a tag for jobs that
  require dedicated, more powerful, or specific hardware.
- GitLab has [autoscaling for runners](https://docs.gitlab.com/runner/configuration/autoscale.html).
  Use autoscaling to provision runners only when needed, and scale down when not needed.
  This is similar to ephemeral agents in Jenkins.

If you are using `gitlab.com`, you can take advantage of our [shared runner fleet](../runners/index.md)
to run jobs without provisioning your own runners. We are investigating making them
[available for self-managed instances](https://gitlab.com/groups/gitlab-org/-/epics/835)
as well.

## Groovy vs. YAML

Jenkins Pipelines are based on [Groovy](https://groovy-lang.org/), so the pipeline specification is written as code.
GitLab works a bit differently, we use the more highly structured [YAML](https://yaml.org/) format, which
places scripting elements inside of `script:` blocks separate from the pipeline specification itself.

This is a strength of GitLab, in that it helps keep the learning curve much simpler to get up and running
and avoids some of the problem of unconstrained complexity which can make your Jenkinsfile hard to understand
and manage.

That said, we do of course still value DRY (don't repeat yourself) principles and want to ensure that
behaviors of your jobs can be codified once and applied as needed. You can use the `extends:` syntax to
[reuse configuration in your jobs](../yaml/index.md#extends), and `include:` can
be used to [reuse pipeline configurations](../yaml/index.md#include) in pipelines
in different projects:

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
or set of files that can then be persisted from job to job. Read more on our detailed
[artifacts documentation](../pipelines/job_artifacts.md):

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - ./mycv.pdf
      - ./output/
    expire_in: 1 week
```

Additionally, we have package management features like built-in container and package registries that you
can leverage. You can see the complete list of packaging features in the
[Packages & Registries](../../user/packages/index.md) documentation.

## Integrated features

Where you may have used plugins to get things like code quality, unit tests, security scanning, and so on working in Jenkins,
GitLab takes advantage of our connected ecosystem to automatically pull these kinds of results into
your Merge Requests, pipeline details pages, and other locations. You may find that you actually don't
need to configure anything to have these appear.

If they aren't working as expected, or if you'd like to see what's available, our [CI feature index](../index.md#feature-set) has the full list
of bundled features and links to the documentation for each.

### Templates

For advanced CI/CD teams, project templates can enable the reuse of pipeline configurations,
as well as encourage inner sourcing.

In self-managed GitLab instances, you can build an [Instance Template Repository](../../user/admin_area/settings/instance_template_repository.md).
Development teams across the whole organization can select templates from a dropdown menu.
A group maintainer or a group owner is able to set a group to use as the source for the
[custom project templates](../../user/admin_area/custom_project_templates.md), which can
be used by all projects in the group. An instance administrator can set a group as
the source for [instance project templates](../../user/group/custom_project_templates.md),
which can be used by projects in that instance.

## Converting a declarative Jenkinsfile

A declarative Jenkinsfile contains "Sections" and "Directives" which are used to control the behavior of your
pipelines. There are equivalents for all of these in GitLab, which we've documented below.

This section is based on the [Jenkinsfile syntax documentation](https://www.jenkins.io/doc/book/pipeline/syntax/)
and is meant to be a mapping of concepts there to concepts in GitLab.

### Sections

#### `agent`

The agent section is used to define how a pipeline executes. For GitLab, we use [runners](../runners/index.md)
to provide this capability. You can configure your own runners in Kubernetes or on any host, or take advantage
of our shared runner fleet (note that the shared runner fleet is only available for GitLab.com users).
We also support using [tags](../runners/configure_runners.md#use-tags-to-limit-the-number-of-jobs-using-the-runner) to direct different jobs
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
is a top level setting that enumerates the list of stages, but you are not required to nest individual jobs underneath
the `stages` section. Any job defined in the `.gitlab-ci.yml` can be made a part of any stage through use of the
[`stage:` keyword](../yaml/index.md#stage).

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
```

#### `steps`

The `steps` section is equivalent to the [`script` section](../yaml/index.md#script) of an individual job. This is
a simple YAML array with each line representing an individual command to be run:

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
including the section on [protected variables](../variables/index.md#protect-a-cicd-variable) which can be used
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

Because GitLab is integrated tightly with Git, SCM polling options for triggers are not needed. We support an easy to use
[syntax for scheduling pipelines](../pipelines/schedules.md).

#### `tools`

GitLab does not support a separate `tools` directive. Our best-practice recommendation is to use pre-built
container images, which can be cached, and can be built to already contain the tools you need for your pipelines. Pipelines can
be set up to automatically build these images as needed and deploy them to the [container registry](../../user/packages/container_registry/index.md).

If you're not using container images with Docker/Kubernetes, for example on Mac or FreeBSD, then the `shell` executor does require you to
set up your environment either in advance or as part of the jobs. You could create a `before_script`
action that handles this for you.

#### `input`

Similar to the `parameters` keyword, this is not needed because a manual job can always be provided runtime
variable entry.

#### `when`

GitLab does support a [`when` keyword](../yaml/index.md#when) which is used to indicate when a job should be
run in case of (or despite) failure, but most of the logic for controlling pipelines can be found in
our very powerful [`rules` system](../yaml/index.md#rules):

```yaml
my_job:
  script:
    - echo
  rules:
    - if: $CI_COMMIT_BRANCH
```

## Additional resources

For help making your pipelines faster and more efficient, see the
[pipeline efficiency documentation](../pipelines/pipeline_efficiency.md).
