---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SaaS runners on macOS (Beta) **(PREMIUM SAAS)**

SaaS runners on macOS are in [Beta](../../../policy/alpha-beta-support.md#beta) for approved open source programs and customers in Premium and Ultimate plans.

SaaS runners on macOS provide an on-demand macOS build environment integrated with
GitLab SaaS [CI/CD](../../../ci/index.md).
Use these runners to build, test, and deploy apps for the Apple ecosystem (macOS, iOS, tvOS). You can take advantage
of all the capabilities of the GitLab single DevOps platform and not have to manage or operate a
build environment. Our [Mobile DevOps solution](../../../ci/mobile_devops.md#ios-build-environments) provides features, documentation, and guidance on building and deploying mobile applications for iOS.

Jobs handled by macOS shared runners on GitLab.com **time out after 3 hours**, regardless of the timeout configured in a project.

## Quickstart

To start using SaaS runners on macOS, you must be an active GitLab SaaS Premium or Ultimate customer.

### Configuring your pipeline

To start using the SaaS runners on macOS to run your CI jobs, you must configure your `.gitlab-ci.yml` file:

1. Add a `.gitlab-ci.yml` file to your project repository.
1. Specify the tag `saas-macos-medium-m1`.
1. Specify the [image](macos/environment.md#vm-images) you want to use.
1. Commit a change to your repository.

The runners automatically run your build.

### Example `.gitlab-ci.yml` file

The following sample `.gitlab-ci.yml` file shows how to start using the SaaS runners on macOS:

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-12-xcode-14

stages:
  - build
  - test

before_script:
  - echo "started by ${GITLAB_USER_NAME}"

build:
  extends:
    - .macos_saas_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .macos_saas_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

NOTE:
You can specify a different Xcode image to run a job. To do so, replace the value for the `image` keyword with the value of the [virtual machine image name](macos/environment.md#vm-images) from the list of available images. The default value is our latest image.

## SaaS runners on macOS service level objective

In SaaS runners on macOS, the objective is to make 90% of CI jobs start executing in 120 seconds or less. The error rate should be less than 0.5%.

## Known Limitations and Usage Constraints

- If the VM image does not include the specific software version you need for your job, then the job execution time will increase as the required software needs to be fetched and installed.
- At this time, it is not possible to bring your own OS image.
- The keychain for user `gitlab` is not publicly available. You must create a keychain instead.
