---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SaaS runners on macOS (Beta) **(PREMIUM SAAS)**

SaaS runners on macOS are in [Beta](../../../policy/experiment-beta-support.md#beta) for open source programs and customers in Premium and Ultimate plans.

SaaS runners on macOS provide an on-demand macOS build environment integrated with
GitLab SaaS [CI/CD](../../../ci/index.md).
Use these runners to build, test, and deploy apps for the Apple ecosystem (macOS, iOS, watchOS, tvOS). You can take advantage
of all the capabilities of the GitLab single DevOps platform and not have to manage or operate a
build environment. Our [Mobile DevOps solution](../../../ci/mobile_devops.md#ios-build-environments) provides features, documentation, and guidance on building and deploying mobile applications for iOS.

We want to keep iterating to get SaaS runners on macOS
[generally available](../../../policy/experiment-beta-support.md#generally-available-ga).
You can follow our work towards this goal in the
[related epic](https://gitlab.com/groups/gitlab-org/-/epics/8267).

## Machine types available for macOS

GitLab SaaS provides macOS build machines on Apple silicon (M1) chips.
Intel x86-64 runners were deprecated in favor of Apple silicon. To build for an x86-64 target, use Rosetta 2 to emulate an Intel x86-64 build environment.

| Runner Tag             | vCPUS | Memory | Storage |
| ---------------------- | ----- | ------ | ------- |
| `saas-macos-medium-m1` | 4     | 8 GB   | 25 GB   |

## Supported macOS images

In comparison to our SaaS runners on Linux, where you can run any Docker image,
GitLab SaaS provides a set of VM images for macOS.

You can execute your build in one of the following images, which you specify
in your `.gitlab-ci.yml` file.

Each image runs a specific version of macOS and Xcode.

| VM image                  | Status        |
|---------------------------|---------------|
| `macos-12-xcode-13`       | `maintenance` |
| `macos-12-xcode-14`       | `maintenance` |
| (none, awaiting macOS 13) | `beta`        |

NOTE:
If your job requires tooling or dependencies not available in our available images, those can only be installed in the job execution.

## Image update policy

GitLab expects to release new images based on this cadence:

macOS updates:

- **For new OS versions:** When Apple releases a new macOS version to developers (like macOS `12`), GitLab will plan to release an image based on the OS within the next 30 business days. The image is considered `beta` and the contents of the image (including tool versions) are subject to change until the first patch release (`12.1`). The long-term name will not include `beta` (for example, `macos-12-xcode-13`), so customers are moved automatically out of beta over time. GitLab will try to minimize breaking changes between the first two minor versions but makes no guarantees. Tooling often gets critical bug fixes after the first public release of an OS version.

- **After the first patch release (`12.1`):**
  - The image moves to `maintenance` mode. The tools GitLab builds into the image with Homebrew and asdf are frozen. GitLab continues making Xcode updates, security updates, and any non-breaking changes deemed necessary.
  - The image for the previous OS version (`11`) moves to `frozen` mode. GitLab then does only unavoidable changes: security updates, runner version upgrades, and setting the production password.

Both macOS and Xcode follow a yearly release cadence. As time goes on, GitLab increments their versions synchronously (meaning we build macOS 11 with Xcode 12, macOS 12 with Xcode 13, and so on).

## Example `.gitlab-ci.yml` file

The following sample `.gitlab-ci.yml` file shows how to start using the SaaS runners on macOS:

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-12-xcode-14
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

## Code signing iOS Projects with fastlane

Before you can integrate GitLab with Apple services, install to a device, or deploy to the Apple App Store, you must [code sign](https://developer.apple.com/support/code-signing/) your application.

Included in each runner on macOS VM image is [fastlane](https://fastlane.tools/),
an open-source solution aimed at simplifying mobile app deployment.

For information about how to set up code signing for your application, see the instructions in the [Mobile DevOps documentation](../../../ci/mobile_devops.md#code-sign-ios-projects-with-fastlane).

Related topics:

- [Apple Developer Support - Code Signing](https://developer.apple.com/support/code-signing/)
- [Code Signing Best Practice Guide](https://codesigning.guide/)
- [fastlane authentication with Apple Services guide](https://docs.fastlane.tools/getting-started/ios/authentication/)

## Optimizing Homebrew

By default, Homebrew checks for updates at the start of any operation. Homebrew has a
release cycle that may be more frequent than the GitLab macOS image release cycle. This
difference in release cycles may cause steps that call `brew` to take extra time to complete
while Homebrew makes updates.

To reduce build time due to unintended Homebrew updates, set the `HOMEBREW_NO_AUTO_UPDATE` variable in `.gitlab-ci.yml`:

```yaml
variables:
  HOMEBREW_NO_AUTO_UPDATE: 1
```

## Known issues and usage constraints

- If the VM image does not include the specific software version you need for your job, the required software must be fetched and installed. This causes an increase in job execution time.
- It is not possible to bring your own OS image.
- The keychain for user `gitlab` is not publicly available. You must create a keychain instead.
