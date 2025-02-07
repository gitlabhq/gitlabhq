---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hosted runners on macOS
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com
**Status:** Beta

Hosted runners on macOS provide an on-demand macOS environment, fully integrated with GitLab [CI/CD](../../_index.md).
You can use these runners to build, test, and deploy apps for the Apple ecosystem (macOS, iOS, watchOS, tvOS).
Our [Mobile DevOps section](../../mobile_devops/mobile_devops_tutorial_ios.md#set-up-your-build-environment) provides features, documentation, and guidance on building and deploying mobile applications for iOS.

Hosted runners on macOS are in [beta](../../../policy/development_stages_support.md#beta) and available for open source programs and customers in Premium and Ultimate plans.
[General availability](../../../policy/development_stages_support.md#generally-available) of Hosted runners on macOS is proposed in [epic 8267](https://gitlab.com/groups/gitlab-org/-/epics/8267).

## Machine types available for macOS

GitLab offers the following machine type for hosted runners on macOS. To build for an x86-64 target, you can use Rosetta 2 to emulate an Intel x86-64 environment.

| Runner Tag               | vCPUS | Memory | Storage |
| ------------------------ | ----- | ------ | ------- |
| `saas-macos-medium-m1`   | 4     | 8 GB   | 50 GB   |
| `saas-macos-large-m2pro` | 6     | 16 GB  | 50 GB   |

## Supported macOS images

In comparison to our hosted runners on Linux, where you can run any Docker image,
GitLab provides a set of VM images for macOS.

You can execute your build in one of the following images, which you specify
in your `.gitlab-ci.yml` file. Each image runs a specific version of macOS and Xcode.

| VM image                   | Status       |              |
|----------------------------|--------------|--------------|
| `macos-13-xcode-14`        | `deprecated` | [Preinstalled Software](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-13-xcode-14/) |
| `macos-14-xcode-15`        | `GA`         | [Preinstalled Software](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-14-xcode-15/) |
| `macos-15-xcode-16`        | `beta`       | [Preinstalled Software](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-15-xcode-16/) |

If no image is specified, the macOS runner uses `macos-14-xcode-15`.

## Image update policy for macOS

The images and installed components are updated with each GitLab release, to keep the preinstalled software up-to-date. GitLab typically supports multiple versions of preinstalled software. For more information, see the [full list of preinstalled software](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/tree/main/toolchain).

Major and minor releases of macOS and Xcode are made available in the milestone subsequent to the Apple release.

A new major release image is initially made available as beta, and becomes generally available with the release of the first minor release.
Because only two generally available images are supported at a time, the oldest image becomes deprecated and will be removed after three months according to the [supported image lifecycle](_index.md#supported-image-lifecycle).

When a new major release is generally available, it becomes the default image for all macOS jobs.

## Example `.gitlab-ci.yml` file

The following sample `.gitlab-ci.yml` file shows how to start using the hosted runners on macOS:

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-14-xcode-15
  before_script:
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

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

Before you can integrate GitLab with Apple services, install to a device, or deploy to the Apple App Store, you must [code sign](https://developer.apple.com/documentation/security/code_signing_services) your application.

Included in each runner on macOS VM image is [fastlane](https://fastlane.tools/),
an open-source solution aimed at simplifying mobile app deployment.

For information about how to set up code signing for your application, see the instructions in the [Mobile DevOps documentation](../../mobile_devops/mobile_devops_tutorial_ios.md#configure-code-signing-with-fastlane).

Related topics:

- [Apple Developer Support - Code Signing](https://forums.developer.apple.com/forums/thread/707080)
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

## Optimizing Cocoapods

If you use Cocoapods in a project, you should consider the following optimizations to improve CI performance.

**Cocoapods CDN**

You can use content delivery network (CDN) access to download packages from the CDN instead of having to clone an entire
project repository. CDN access is available in Cocoapods 1.8 or later and is supported by all GitLab hosted runners on macOS.

To enable CDN access, ensure your Podfile starts with:

```ruby
source 'https://cdn.cocoapods.org/'
```

**Use GitLab caching**

Use caching in Cocoapods packages in GitLab to only run `pod install`
when pods change, which can improve build performance.

To [configure caching](../../caching/_index.md) for your project:

1. Add the `cache` configuration to your `.gitlab-ci.yml` file:

   ```yaml
   cache:
     key:
       files:
        - Podfile.lock
   paths:
     - Pods
   ```

1. Add the [`cocoapods-check`](https://guides.cocoapods.org/plugins/optimising-ci-times.html) plugin to your project.
1. Update the job script to check for installed dependencies before it calls `pod install`:

   ```shell
   bundle exec pod check || bundle exec pod install
   ```

**Include pods in source control**

You can also [include the pods directory in source control](https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control). This eliminates the need to install pods as part of the CI job,
but it does increase the overall size of your project's repository.

## Known issues and usage constraints

- If the VM image does not include the specific software version you need for your job, the required software must be fetched and installed. This causes an increase in job execution time.
- It is not possible to bring your own OS image.
- The keychain for user `gitlab` is not publicly available. You must create a keychain instead.
- Hosted runners on macOS run in headless mode.
  Any workloads that require UI interactions such as `testmanagerd` are not supported.
- Job performance might vary between job executions as Apple silicon chips have efficiency and
  performance cores. You can't control core allocation or scheduling, which might lead to inconsistencies.
