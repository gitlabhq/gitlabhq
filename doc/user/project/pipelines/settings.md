# CI/CD pipelines settings

To reach the pipelines settings:

1. Navigate to your project and click the cog icon in the upper right corner.

    ![Project settings menu](../img/project_settings_list.png)

1. Select **CI/CD Pipelines** from the menu.

The following settings can be configured per project.

## Git strategy

With Git strategy, you can choose the default way your repository is fetched
from GitLab in a job.

There are two options:

- Using `git clone` which is slower since it clones the repository from scratch
  for every job, ensuring that the project workspace is always pristine.
- Using `git fetch` which is faster as it re-uses the project workspace (falling
  back to clone if it doesn't exist).

The default Git strategy can be overridden by the [GIT_STRATEGY variable][var]
in `.gitlab-ci.yml`.

## Timeout

Timeout defines the maximum amount of time in minutes that a job is able run.
The default value is 60 minutes. Decrease the time limit if you want to impose
a hard limit on your jobs' running time or increase it otherwise. In any case,
if the job surpasses the threshold, it is marked as failed.

## Test coverage parsing

If you use test coverage in your code, GitLab can capture its output in the
build trace using a regular expression. Leave blank if you want to disable it
or enter a ruby regular expression. You can use http://rubular.com to test your
regex.

A few examples can be found in the settings page.

## Visibility of pipelines

For public and internal projects, the **Pipelines** page can be accessed by
anyone and those logged in respectively. If you wish to hide it so that only
the members of the project or group have access to it, uncheck the **Public
pipelines** checkbox and save the changes.

## Badges

In the pipelines settings page you can find build status and test coverage
badges for your project. The latest successful pipeline will be used to read
the build status and test coverage values.

Visit the **Pipelines** settings page in your project to see the exact link to
your badges, as well as ways to embed the badge image in your HTML or Markdown
pages.

![Pipelines badges](img/pipelines_settings_badges.png)

### Build status badge

Depending on the status of your build, a badge can have the following values:

- running
- success
- failed
- skipped
- unknown

You can access a build status badge image using the following link:

```
https://example.gitlab.com/<namespace>/<project>/badges/<branch>/build.svg
```

### Test coverage report badge

GitLab makes it possible to define the regular expression for [coverage report],
that each build log will be matched against. This means that each build in the
pipeline can have the test coverage percentage value defined.

The test coverage badge can be accessed using following link:

```
https://example.gitlab.com/<namespace>/<project>/badges/<branch>/coverage.svg
```

If you would like to get the coverage report from a specific job, you can add
the `job=coverage_job_name` parameter to the URL. For example, the following
Markdown code will embed the test coverage report badge of the `coverage` job
into your `README.md`:

```markdown
![coverage](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg?job=coverage)
```

[var]: ../../../ci/yaml/README.md#git-strategy
[coverage report]: #test-coverage-parsing
