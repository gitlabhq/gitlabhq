---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---
<!-- markdownlint-disable MD044 -->
# The .gitlab-ci.yml file
<!-- markdownlint-enable MD044 -->

To use GitLab CI/CD, you need an application codebase hosted in a
Git repository, and for your build, test, and deployment
scripts to be specified in a file called [`.gitlab-ci.yml`](README.md),
located in the root path of your repository.

In this file, you can define the scripts you want to run, define include and
cache dependencies, choose commands you want to run in sequence
and those you want to run in parallel, define where you want to
deploy your app, and specify whether you want to run the scripts automatically
or trigger any of them manually. After you're familiar with
GitLab CI/CD you can add more advanced steps into the configuration file.

To add scripts to that file, you need to organize them in a
sequence that suits your application and are in accordance with
the tests you wish to perform. To visualize the process, imagine
that all the scripts you add to the configuration file are the
same as the commands you run on a terminal on your computer.

After you've added your `.gitlab-ci.yml` configuration file to your
repository, GitLab detects it and run your scripts with the
tool called [GitLab Runner](https://docs.gitlab.com/runner/), which
works similarly to your terminal.

The scripts are grouped into **jobs**, and together they compose
a **pipeline**. A minimalist example of `.gitlab-ci.yml` file
could contain:

```yaml
before_script:
  - apt-get install rubygems ruby-dev -y

run-test:
  script:
    - ruby --version
```

The `before_script` attribute would install the dependencies
for your app before running anything, and a  **job** called
`run-test` would print the Ruby version of the current system.
Both of them compose a **pipeline** triggered at every push
to any branch of the repository.

GitLab CI/CD not only executes the jobs you've
set but also shows you what's happening during execution, as you
would see in your terminal:

![job running](img/job_running.png)

You create the strategy for your app and GitLab runs the pipeline
for you according to what you've defined. Your pipeline status is also
displayed by GitLab:

![pipeline status](img/pipeline_status.png)

At the end, if anything goes wrong, you can easily
[roll back](../environments/index.md#retrying-and-rolling-back) all the changes:

![rollback button](img/rollback.png)

[View the full syntax for the `.gitlab-ci.yml` file](README.md).
