---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SaaS runners on macOS (Beta) **(PREMIUM SAAS)**

SaaS runners on macOS are in [Beta](../../../policy/experiment-beta-support.md#beta) for approved open source programs and customers in Premium and Ultimate plans.

SaaS runners on macOS provide an on-demand macOS build environment integrated with
GitLab SaaS [CI/CD](../../../ci/index.md).
Use these runners to build, test, and deploy apps for the Apple ecosystem (macOS, iOS, watchOS, tvOS). You can take advantage
of all the capabilities of the GitLab single DevOps platform and not have to manage or operate a
build environment. Our [Mobile DevOps solution](../../../ci/mobile_devops.md#ios-build-environments) provides features, documentation, and guidance on building and deploying mobile applications for iOS.

## Machine types available for macOS

GitLab SaaS provides macOS build machines on Apple silicon (M1) chips.
Intel x86-64 runners were deprecated in favor of Apple silicon. To build for an x86-64 target, use Rosetta 2 to emulate an Intel x86-64 build environment.

| Instance type | vCPUS | Memory (GB) |
| --------- | --- | ------- |
|  `saas-macos-medium-m1` | 4 | 8 |

## VM images

In comparison to our SaaS runners on Linux, where you can run any Docker image,
GitLab SaaS provides a set of VM images for macOS.

### Supported macOS images

You can execute your build in one of the following images, which you specify
in your `.gitlab-ci.yml` file.

Each image runs a specific version of macOS and Xcode.

| VM image                  | Status | Included software  |
|---------------------------|--------|--------------------|
| `macos-12-xcode-13`       | `maintenance` |  |
| `macos-12-xcode-14`       | `maintenance` |  |
| (none, awaiting macOS 13) | `beta` |  |

NOTE:
Each time you run a job that requires tooling or dependencies not available in the base image, those items must be added to the newly provisioned build VM. That installation process will likely increase the total job duration.

### Image update policy

GitLab expects to release new images based on this cadence:

macOS updates:

- **For new OS versions:** When Apple releases a new macOS version to developers (like macOS `12`), GitLab will plan to release an image based on the OS within the next 30 business days. The image is considered `beta` and the contents of the image (including tool versions) are subject to change until the first patch release (`12.1`). The long-term name will not include `beta` (for example, `macos-12-xcode-13`), so customers are moved automatically out of beta over time. GitLab will try to minimize breaking changes between the first two minor versions but makes no guarantees. Tooling often gets critical bug fixes after the first public release of an OS version.

- **After the first patch release (`12.1`):**
  - The image moves to `maintenance` mode. The tools GitLab builds into the image with Homebrew and asdf are frozen. GitLab continues making Xcode updates, security updates, and any non-breaking changes deemed necessary.
  - The image for the previous OS version (`11`) moves to `frozen` mode. GitLab then does only unavoidable changes: security updates, runner version upgrades, and setting the production password.

Both macOS and Xcode follow a yearly release cadence. As time goes on, GitLab increments their versions synchronously (meaning we build macOS 11 with Xcode 12, macOS 12 with Xcode 13, and so on).

## Quickstart

To start using SaaS runners on macOS, you must be an active GitLab SaaS Premium or Ultimate customer.

### Configuring your pipeline

To start using the SaaS runners on macOS to run your CI jobs, you must configure your `.gitlab-ci.yml` file:

1. Add a `.gitlab-ci.yml` file to your project repository.
1. Specify the tag `saas-macos-medium-m1`.
1. Specify the [image](#supported-macos-images) you want to use.
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
You can specify a different Xcode image to run a job. To do so, replace the value for the `image` keyword with the value of the [virtual machine image name](#supported-macos-images) from the list of available images. The default value is our latest image.

## Code signing for SaaS runners on macOS

Before you can integrate GitLab with Apple services, install to a device, or deploy to the Apple App Store, you must [code sign](https://developer.apple.com/support/code-signing/) your application.

### Code signing iOS Projects with fastlane

When you use SaaS runners on macOS, each job runs on a VM. Included in each VM is [fastlane](https://fastlane.tools/),
an open-source solution aimed at simplifying mobile app deployment.

For information about how to set up code signing for your application, see the instructions in the [Mobile DevOps documentation](../../../ci/mobile_devops.md#code-sign-ios-projects-with-fastlane).

### Related topics

- [Apple Developer Support - Code Signing](https://developer.apple.com/support/code-signing/)
- [Code Signing Best Practice Guide](https://codesigning.guide/)
- [fastlane authentication with Apple Services guide](https://docs.fastlane.tools/getting-started/ios/authentication/)

## SaaS runners on macOS service level objective

In SaaS runners on macOS, the objective is to make 90% of CI jobs start executing in 120 seconds or less. The error rate should be less than 0.5%.

## Known Limitations and Usage Constraints

- If the VM image does not include the specific software version you need for your job, then the job execution time will increase as the required software needs to be fetched and installed.
- At this time, it is not possible to bring your own OS image.
- The keychain for user `gitlab` is not publicly available. You must create a keychain instead.
