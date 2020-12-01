---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: tutorial
---

# Test and deploy a Scala application to Heroku

This example demonstrates the integration of GitLab CI/CD with Scala
applications using SBT. You can view or fork the [example project](https://gitlab.com/gitlab-examples/scala-sbt)
and view the logs of its past [CI jobs](https://gitlab.com/gitlab-examples/scala-sbt/-/jobs?scope=finished).

## Add `.gitlab-ci.yml` file to project

The following `.gitlab-ci.yml` should be added in the root of your
repository to trigger CI:

``` yaml
image: openjdk:8

stages:
  - test
  - deploy

before_script:
  - apt-get update -y
  - apt-get install apt-transport-https -y
  ## Install SBT
  - echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
  - apt-get update -y
  - apt-get install sbt -y
  - sbt sbtVersion

test:
  stage: test
  script:
    - sbt clean coverage test coverageReport

deploy:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install rubygems ruby-dev -y
    - gem install dpl
    - dpl --provider=heroku --app=gitlab-play-sample-app --api-key=$HEROKU_API_KEY
```

In the above configuration:

- The `before_script` installs [SBT](https://www.scala-sbt.org/) and
  displays the version that is being used.
- The `test` stage executes SBT to compile and test the project.
  - [sbt-scoverage](https://github.com/scoverage/sbt-scoverage) is used as an SBT
    plugin to measure test coverage.
- The `deploy` stage automatically deploys the project to Heroku using dpl.

You can use other versions of Scala and SBT by defining them in
`build.sbt`.

## Display test coverage in job

Add the `Coverage was \[\d+.\d+\%\]` regular expression in the
**Settings > Pipelines > Coverage report** project setting to
retrieve the [test coverage](../pipelines/settings.md#test-coverage-report-badge)
rate from the build trace and have it displayed with your jobs.

**Pipelines** must be enabled for this option to appear.

## Heroku application

A Heroku application is required. You can create one through the
[Dashboard](https://dashboard.heroku.com/). Substitute `gitlab-play-sample-app`
in the `.gitlab-ci.yml` file with your application's name.

## Heroku API key

You can look up your Heroku API key in your
[account](https://dashboard.heroku.com/account). Add a [protected variable](../variables/README.md#protect-a-custom-variable) with
this value in **Project ➔ Variables** with key `HEROKU_API_KEY`.
