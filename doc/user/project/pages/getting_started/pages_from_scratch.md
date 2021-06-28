---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create a GitLab Pages website from scratch **(FREE)**

This tutorial shows you how to create a Pages site from scratch. You start with
a blank project and create your own CI file, which gives instruction to
a [runner](https://docs.gitlab.com/runner/). When your CI/CD
[pipeline](../../../../ci/pipelines/index.md) runs, the Pages site is created.

This example uses the [Jekyll](https://jekyllrb.com/) Static Site Generator (SSG).
Other SSGs follow similar steps. You do not need to be familiar with Jekyll or SSGs
to complete this tutorial.

## Prerequisites

To follow along with this example, start with a blank project in GitLab.
Create three files in the root (top-level) directory.

- `.gitlab-ci.yml` A YAML file that contains the commands you want to run.
  For now, leave the file's contents blank.

- `index.html` An HTML file you can populate with whatever HTML content you'd like,
  for example:

  ```html
  <html>
  <head>
    <title>Home</title>
  </head>
  <body>
    <h1>Hello World!</h1>
  </body>
  </html>
  ```

- [`Gemfile`](https://bundler.io/gemfile.html) A file that describes dependencies for Ruby programs.
  Populate it with this content:

  ```ruby
  source "https://rubygems.org"

  gem "jekyll"
  ```

## Choose a Docker image

In this example, the runner uses a [Docker image](../../../../ci/docker/using_docker_images.md)
to run scripts and deploy the site.

This specific Ruby image is maintained on [DockerHub](https://hub.docker.com/_/ruby).

Edit your `.gitlab-ci.yml` and add this text as the first line.

```yaml
image: ruby:2.7
```

If your SSG needs [NodeJS](https://nodejs.org/) to build, you must specify an
image that contains NodeJS as part of its file system. For example, for a
[Hexo](https://gitlab.com/pages/hexo) site, you can use `image: node:12.17.0`.

## Install Jekyll

To run [Jekyll](https://jekyllrb.com/) locally, you would open your terminal and:

- Install [Bundler](https://bundler.io/) by running `gem install bundler`.
- Create `Gemfile.lock` by running `bundle install`.
- Install Jekyll by running `bundle exec jekyll build`.

In the `.gitlab-ci.yml` file, this is written as:

```yaml
script:
  - gem install bundler
  - bundle install
  - bundle exec jekyll build
```

In addition, in the `.gitlab-ci.yml` file, each `script` is organized by a `job`.
A `job` includes the scripts and settings you want to apply to that specific
task.

```yaml
job:
  script:
  - gem install bundler
  - bundle install
  - bundle exec jekyll build
```

For GitLab Pages, this `job` has a specific name, called `pages`.
This setting tells the runner you want the job to deploy your website
with GitLab Pages:

```yaml
pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build
```

## Specify the `public` directory for output

Jekyll needs to know where to generate its output.
GitLab Pages only considers files in a directory called `public`.

Jekyll uses destination (`-d`) to specify an output directory for the built website:

```yaml
pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
```

## Specify the `public` directory for artifacts

Now that Jekyll has output the files to the `public` directory,
the runner needs to know where to get them. The artifacts are stored
in the `public` directory:

```yaml
pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
```

Paste this into `.gitlab-ci.yml` file, so it now looks like this:

```yaml
image: ruby:2.7

pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
```

Now save and commit the `.gitlab-ci.yml` file. You can watch the pipeline run
by going to **CI/CD > Pipelines**.

When it succeeds, go to **Settings > Pages** to view the URL where your site
is now available.

If you want to do more advanced tasks, you can update your `.gitlab-ci.yml` file
with [any of the available settings](../../../../ci/yaml/index.md). You can validate
your `.gitlab-ci.yml` file with the [CI Lint](../../../../ci/lint.md) tool that's included with GitLab.

After successful execution of this `pages` job, a special `pages:deploy` job appears in the
pipeline view. It prepares the content of the website for GitLab Pages daemon. GitLab executes it in
the background and doesn't use runner.

The following topics show other examples of other options you can add to your CI/CD file.

## Deploy specific branches to a Pages site

You may want to deploy to a Pages site only from specific branches.

First, add a `workflow` section to force the pipeline to run only when changes are
pushed to branches:

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
```

Then configure the pipeline to run the job for the `master` branch only.

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
```

## Specify a stage to deploy

There are three default stages for GitLab CI/CD: build, test,
and deploy.

If you want to test your script and check the built site before deploying
to production, you can run the test exactly as it runs when you
push to `master`.

To specify a stage for your job to run in,
add a `stage` line to your CI file:

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
```

Now add another job to the CI file, telling it to
test every push to every branch **except** the `master` branch:

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'

test:
  stage: test
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: '$CI_COMMIT_BRANCH != "master"'
```

When the `test` job runs in the `test` stage, Jekyll
builds the site in a directory called `test`. The job affects
all branches except `master`.

When you apply stages to different jobs, every job in the same
stage builds in parallel. If your web application needs more than
one test before being deployed, you can run all your tests at the
same time.

## Remove duplicate commands

To avoid duplicating the same scripts in every job, you can add them
to a `before_script` section.

In the example, `gem install bundler` and `bundle install` were running
for both jobs, `pages` and `test`.

Move these commands to a `before_script` section:

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

before_script:
  - gem install bundler
  - bundle install

pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: '$CI_COMMIT_BRANCH != "master"'
```

## Build faster with cached dependencies

To build faster, you can cache the installation files for your
project's dependencies by using the `cache` parameter.

This example caches Jekyll dependencies in a `vendor` directory
when you run `bundle install`:

```yaml
image: ruby:2.7

workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'

cache:
  paths:
    - vendor/

before_script:
  - gem install bundler
  - bundle install --path vendor

pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: '$CI_COMMIT_BRANCH != "master"'
```

In this case, you need to exclude the `/vendor`
directory from the list of folders Jekyll builds. Otherwise, Jekyll
tries to build the directory contents along with the site.

In the root directory, create a file called `_config.yml`
and add this content:

```yaml
exclude:
  - vendor
```

Now GitLab CI/CD not only builds the website,
but also pushes with **continuous tests** to feature-branches,
**caches** dependencies installed with Bundler, and
**continuously deploys** every push to the `master` branch.

## Related topics

For more information, see the following blog posts.

- [Use GitLab CI/CD `environments` to deploy your
  web app to staging and production](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/).
- Learn [how to run jobs sequentially,
  in parallel, or build a custom pipeline](https://about.gitlab.com/blog/2016/07/29/the-basics-of-gitlab-ci/).
- Learn [how to pull specific directories from different projects](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
  to deploy this website, <https://docs.gitlab.com>.
- Learn [how to use GitLab Pages to produce a code coverage report](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/).
