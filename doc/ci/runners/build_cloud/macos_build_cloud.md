---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Build Cloud runners for macOS (Beta)

The GitLab Build Cloud for macOS Beta provides on-demand runners integrated with GitLab SaaS [CI/CD](../../../ci/index.md).
Use these runners to build, test, and deploy apps for the Apple ecosystem (macOS, iOS, tvOS). You can take advantage
of all the capabilities of the GitLab single DevOps platform and not have to manage or operate a
build environment.

Build Cloud runners for macOS are in [Beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta)
and shouldn't be relied upon for mission-critical production jobs. 

## Quickstart

To start using Build Cloud for macOS Beta, you must submit an access request issue. After your
access has been granted and your build environment configured, you must configure your
`.gitlab-ci.yml` pipeline file:

1. Add a `.gitlab-ci.yml` file to your project repository.
1. Specify the [image](macos/environment.md#vm-images) you want to use.
1. Commit a change to your repository.

The runners automatically run your build.

## Example `.gitlab-ci.yml` file

The following sample `.gitlab-ci.yml` file shows how to start using the runners for macOS:

```yaml
.macos_buildcloud_runners:
  tags:
    - shared-macos-amd64
  image: macos-11-xcode-12

stages:
  - build
  - test

before_script:
 - echo "started by ${GITLAB_USER_NAME}"

build:
  extends:
    - .macos_buildcloud_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .macos_buildcloud_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

NOTE:
During the Beta period, the architecture of this solution will change. Rather than the jobs running on a specific VM instance, they will run on an ephemeral VM instance that is created by an autoscaling instance, known as the Runner Manager. We will notify all Beta participants of any downtime required to do this work.
