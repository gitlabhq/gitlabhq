---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Create a GitLab Pages website from scratch'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This tutorial shows you how to create a Pages site from scratch using
the [Jekyll](https://jekyllrb.com/) Static Site Generator (SSG). You start with
a blank project and create your own CI/CD configuration file, which gives
instructions to a [runner](https://docs.gitlab.com/runner/). When your CI/CD
[pipeline](../../../../ci/pipelines/_index.md) runs, the Pages site is created.

This example uses Jekyll, but other SSGs follow similar steps.
You do not need to be familiar with Jekyll or SSGs
to complete this tutorial.

To create a GitLab Pages website:

- [Step 1: Create the project files](#create-the-project-files)
- [Step 2: Choose a Docker image](#choose-a-docker-image)
- [Step 3: Install Jekyll](#install-jekyll)
- [Step 4: Specify the `public` directory for output](#specify-the-public-directory-for-output)
- [Step 5: Specify the `public` directory for artifacts](#specify-the-public-directory-for-artifacts)
- [Step 6: Deploy and view your website](#deploy-and-view-your-website)

## Prerequisites

You must have a [blank project](../../_index.md#create-a-blank-project) in GitLab.

## Create the project files

Create three files in the root (top-level) directory:

- `.gitlab-ci.yml`: A YAML file that contains the commands you want to run.
  For now, leave the file's contents blank.

- `index.html`: An HTML file you can populate with whatever HTML content
  you'd like, for example:

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

- [`Gemfile`](https://bundler.io/gemfile.html): A file that describes dependencies for Ruby programs.

  Populate it with this content:

  ```ruby
  source "https://rubygems.org"

  gem "jekyll"
  ```

## Choose a Docker image

In this example, the runner uses a [Docker image](../../../../ci/docker/using_docker_images.md)
to run scripts and deploy the site.

This specific Ruby image is maintained on [DockerHub](https://hub.docker.com/_/ruby).

Add a default image to your pipeline by adding this CI/CD configuration to the beginning of your `.gitlab-ci.yml` file:

```yaml
default:
  image: ruby:3.2
```

If your SSG needs [NodeJS](https://nodejs.org/) to build, you must specify an
image that contains NodeJS as part of its file system. For example, for a
[Hexo](https://gitlab.com/pages/hexo) site, you can use `image: node:12.17.0`.

## Install Jekyll

To run [Jekyll](https://jekyllrb.com/) locally, you must install it:

1. Open your terminal.
1. Install [Bundler](https://bundler.io/) by running `gem install bundler`.
1. Create `Gemfile.lock` by running `bundle install`.
1. Install Jekyll by running `bundle exec jekyll build`.

To run Jekyll in your project, edit the `.gitlab-ci.yml` file
and add the installation commands:

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

For GitLab Pages, this `job` has to include a property, called `pages`.
This setting tells the runner you want the job to deploy your website
with GitLab Pages:

```yaml
deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build
  pages: true  # specifies that this is a Pages job
```

The example in this page uses [user-defined job names](../_index.md#user-defined-job-names).

## Specify the `public` directory for output

Jekyll needs to know where to generate its output.
GitLab Pages only considers files in a directory called `public`.

Jekyll uses a destination flag (`-d`) to specify an output directory for the built website.
Add the destination to your `.gitlab-ci.yml` file:

```yaml
deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
```

## Specify the `public` directory for artifacts

Now that Jekyll has output the files to the `public` directory,
the runner needs to know where to get them. The artifacts are stored
in the `public` directory:

```yaml
deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
```

Your `.gitlab-ci.yml` file should now look like this:

```yaml
default:
  image: ruby:3.2

deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
```

## Deploy and view your website

After you have completed the preceding steps,
deploy your website:

1. Save and commit the `.gitlab-ci.yml` file.
1. Go to **Build > Pipelines** to watch the pipeline.
1. When the pipeline is finished, go to **Deploy > Pages** to find the link to
   your Pages website.

When this `pages` job completes successfully, a special `pages:deploy` job
appears in the pipeline view. It prepares the content of the website for the
GitLab Pages daemon. GitLab runs it in the background and doesn't use a runner.

## Other options for your CI/CD file

If you want to do more advanced tasks, you can update your `.gitlab-ci.yml` file
with [other CI/CD YAML keywords](../../../../ci/yaml/_index.md). You can validate
your `.gitlab-ci.yml` file with the [CI Lint](../../../../ci/yaml/lint.md) tool that's included with GitLab.

The following topics show other examples of other options you can add to your CI/CD file.

### Deploy specific branches to a Pages site

You may want to deploy to a Pages site only from specific branches.

First, add a `workflow` section to force the pipeline to run only when changes are
pushed to branches:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
```

Then configure the pipeline to run the job for the
[default branch](../../repository/branches/default.md) (here, `main`) only.

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

deploy-pages:
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Specify a stage to deploy

There are three default stages for GitLab CI/CD: build, test,
and deploy.

If you want to test your script and check the built site before deploying
to production, you can run the test exactly as it runs when you
push to your [default branch](../../repository/branches/default.md) (here, `main`).

To specify a stage for your job to run in,
add a `stage` line to your CI file:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

deploy-pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production
```

Now add another job to the CI file, telling it to
test every push to every branch **except** the `main` branch:

```yaml
default:
  image: ruby:3.2

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

deploy-pages:
  stage: deploy
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

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
    - if: $CI_COMMIT_BRANCH != "main"
```

When the `test` job runs in the `test` stage, Jekyll
builds the site in a directory called `test`. The job affects
all branches except `main`.

When you apply stages to different jobs, every job in the same
stage builds in parallel. If your web application needs more than
one test before being deployed, you can run all your tests at the
same time.

### Remove duplicate commands

To avoid duplicating the same `before_script` commands in every job, you can add them
to the default section.

In the example, `gem install bundler` and `bundle install` were running
for both jobs, `pages` and `test`.

Move these commands to the `default` section:

```yaml
default:
  image: ruby:3.2
  before_script:
    - gem install bundler
    - bundle install

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

deploy-pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
```

### Build faster with cached dependencies

To build faster, you can cache the installation files for your
project's dependencies by using the `cache` parameter.

This example caches Jekyll dependencies in a `vendor` directory
when you run `bundle install`:

```yaml
default:
  image: ruby:3.2
  before_script:
    - gem install bundler
    - bundle install --path vendor
  cache:
    paths:
      - vendor/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH


deploy-pages:
  stage: deploy
  script:
    - bundle exec jekyll build -d public
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production

test:
  stage: test
  script:
    - bundle exec jekyll build -d test
  artifacts:
    paths:
      - test
  rules:
    - if: $CI_COMMIT_BRANCH != "main"
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

Now GitLab CI/CD not only builds the website, but also:

- Pushes with **continuous tests** to feature branches.
- **Caches** dependencies installed with Bundler.
- **Continuously deploys** every push to the `main` branch.

To view the HTML and other assets that were created for the site,
[download the job artifacts](../../../../ci/jobs/job_artifacts.md#download-job-artifacts).

The example in this page uses [user-defined job names](../_index.md#user-defined-job-names).

## Related topics

- [Deploy your web app to staging and production](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/)
- [Run jobs sequentially, in parallel, or build a custom pipeline](https://about.gitlab.com/blog/2020/12/10/basics-of-gitlab-ci-updated/)
- [Pull specific directories from different projects](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
- [Use GitLab Pages to produce a code coverage report](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/)
