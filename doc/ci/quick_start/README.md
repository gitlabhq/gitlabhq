---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Getting started with GitLab CI/CD

GitLab offers a [continuous integration](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) service. For each commit or push to trigger your CI
[pipeline](../pipelines/index.md), you must:

- Add a [`.gitlab-ci.yml` file](#creating-a-gitlab-ciyml-file) to your repository's root directory.
- Ensure your project is configured to use a [runner](#configuring-a-runner).

The `.gitlab-ci.yml` file defines the structure and order of the pipelines, and determines:

- What to execute using [GitLab Runner](https://docs.gitlab.com/runner/).
- What decisions to make when specific conditions are encountered. For example, when a process succeeds or fails.

A simple pipeline commonly has
three [stages](../yaml/README.md#stages):

- `build`
- `test`
- `deploy`

You do not need to use all three stages; stages with no jobs are ignored.

The pipeline appears under the project's **CI/CD > Pipelines** page. If everything runs OK (no non-zero
return values), you get a green check mark associated with the commit. This makes it easy to see
whether a commit caused any of the tests to fail before you even look at the job (test) log. Many projects use
GitLab's CI service to run the test suite, so developers get immediate feedback if they broke
something.

It's also common to use pipelines to automatically deploy
tested code to staging and production environments.

If you're already familiar with general CI/CD concepts, you can review which
[pipeline architectures](../pipelines/pipeline_architectures.md) can be used
in your projects. If you're coming over to GitLab from Jenkins, you can check out
our [reference](../migration/jenkins.md) for converting your pre-existing pipelines
over to our format.

This guide assumes that you have:

- A working GitLab instance of version 8.0+ or are using
  [GitLab.com](https://gitlab.com).
- A project in GitLab that you would like to use CI for.
- Maintainer or owner access to the project

Let's break it down to pieces and work on solving the GitLab CI/CD puzzle.

## Creating a `.gitlab-ci.yml` file

Before you create `.gitlab-ci.yml` let's first explain in brief what this is
all about.

### What is `.gitlab-ci.yml`

The `.gitlab-ci.yml` file is where you configure what CI does with your project.
It lives in the root of your repository.

On any push to your repository, GitLab will look for the `.gitlab-ci.yml`
file and start jobs on _runners_ according to the contents of the file,
for that commit.

Because `.gitlab-ci.yml` is in the repository and is version controlled, old
versions still build successfully, forks can easily make use of CI, branches can
have different pipelines and jobs, and you have a single source of truth for CI.
You can read more about the reasons why we are using `.gitlab-ci.yml` [in our
blog about it](https://about.gitlab.com/blog/2015/05/06/why-were-replacing-gitlab-ci-jobs-with-gitlab-ci-dot-yml/).

### Creating a simple `.gitlab-ci.yml` file

You need to create a file named `.gitlab-ci.yml` in the root directory of your
repository. This is a [YAML](https://en.wikipedia.org/wiki/YAML) file
so you have to pay extra attention to indentation. Always use spaces, not tabs.

Below is an example for a Ruby on Rails project:

```yaml
default:
  image: ruby:2.5
  before_script:
    - apt-get update
    - apt-get install -y sqlite3 libsqlite3-dev nodejs
    - ruby -v
    - which ruby
    - gem install bundler --no-document
    - bundle install --jobs $(nproc) "${FLAGS[@]}"

rspec:
  script:
    - bundle exec rspec

rubocop:
  script:
    - bundle exec rubocop
```

This is the simplest possible configuration that will work for most Ruby
applications:

1. Define two jobs `rspec` and `rubocop` (the names are arbitrary) with
   different commands to be executed.
1. Before every job, the commands defined by `before_script` are executed.

The `.gitlab-ci.yml` file defines sets of jobs with constraints of how and when
they should be run. The jobs are defined as top-level elements with a name (in
our case `rspec` and `rubocop`) and always have to contain the `script` keyword.
Jobs are used to create jobs, which are then picked by
[runners](../runners/README.md) and executed within the environment of the runner.

What is important is that each job is run independently from each other.

If you want to check whether the `.gitlab-ci.yml` of your project is valid, there is a
[CI Lint tool](../lint.md) available in every project.

You can use the [CI/CD configuration visualization](../yaml/visualization.md) to
see a graphical representation of your `.gitlab-ci.yml`.

For more information and a complete `.gitlab-ci.yml` syntax, please read
[the reference documentation on `.gitlab-ci.yml`](../yaml/README.md).

TIP: **Tip:**
A GitLab team member has made an [unofficial visual pipeline editor](https://unofficial.gitlab.tools/visual-pipelines/).
There is a [plan to make it an official part of GitLab](https://gitlab.com/groups/gitlab-org/-/epics/4069)
in the future, but it's available for anyone who wants to try it at the above link.

### Push `.gitlab-ci.yml` to GitLab

After you've created a `.gitlab-ci.yml`, you should add it to your Git repository
and push it to GitLab.

```shell
git add .gitlab-ci.yml
git commit -m "Add .gitlab-ci.yml"
git push origin master
```

Now if you go to the **Pipelines** page you will see that the pipeline is
pending.

NOTE: **Note:**
If you have a [mirrored repository where GitLab pulls from](../../user/project/repository/repository_mirroring.md#pulling-from-a-remote-repository),
you may need to enable pipeline triggering in your project's
**Settings > Repository > Pull from a remote repository > Trigger pipelines for mirror updates**.

You can also go to the **Commits** page and notice the little pause icon next
to the commit SHA.

![New commit pending](img/new_commit.png)

Clicking on it you will be directed to the jobs page for that specific commit.

![Single commit jobs page](img/single_commit_status_pending.png)

Notice that there is a pending job which is named after what we wrote in
`.gitlab-ci.yml`. "stuck" indicates that there is no runner configured
yet for this job.

The next step is to configure a runner so that it picks the pending jobs.

## Configuring a runner

In GitLab, runners run the jobs that you define in `.gitlab-ci.yml`. A runner
can be a virtual machine, a VPS, a bare-metal machine, a Docker container, or
even a cluster of containers. GitLab and the runner communicate through an API,
so the only requirement is that the runner's machine has network access to the
GitLab server.

A runner can be specific to a certain project or serve multiple projects in
GitLab. If it serves all projects, it's called a _shared runner_.

Find more information about runners in the
[runner](../runners/README.md) documentation.

The official runner supported by GitLab is written in Go.
View [the documentation](https://docs.gitlab.com/runner/).

For a runner to be available in GitLab, you must:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. [Register a runner for your group or project](https://docs.gitlab.com/runner/register/).

When a runner is available, you can view it by
clicking **Settings > CI/CD** and expanding **Runners**.

![Activated runners](img/runners_activated.png)

### Shared runners

If you use [GitLab.com](https://gitlab.com/), you can use the **shared runners**
provided by GitLab.

These are special virtual machines that run on GitLab's infrastructure and can
build any project.

To enable shared runners, go to your project's or group's
**Settings > CI/CD** and click **Enable shared runners**.

[Read more about shared runners](../runners/README.md#shared-runners).

## Viewing the status of your pipeline and jobs

After configuring the runner successfully, you should see the status of your
last commit change from _pending_ to either _running_, _success_ or _failed_.

You can view all pipelines by going to the **Pipelines** page in your project.

![Commit status](img/pipelines_status.png)

Or you can view all jobs, by going to the **Pipelines ➔ Jobs** page.

![Commit status](img/builds_status.png)

By clicking on a job's status, you will be able to see the log of that job.
This is important to diagnose why a job failed or acted differently than
you expected.

![Build log](img/build_log.png)

You are also able to view the status of any commit in the various pages in
GitLab, such as **Commits** and **Merge requests**.

## Additional resources

Visit the [examples README](../examples/README.md) to see a list of examples using GitLab
CI with various languages.

For help making your new pipelines faster and more efficient, see the
[pipeline efficiency documentation](../pipelines/pipeline_efficiency.md).
