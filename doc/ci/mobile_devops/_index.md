---
stage: Mobile
group: Mobile Devops
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mobile DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Build, sign, and release native and cross-platform mobile apps for Android and iOS by using GitLab CI/CD.
GitLab Mobile DevOps provides tools and best practices to automate your mobile app development workflow.

GitLab Mobile DevOps integrates key mobile development capabilities into the GitLab DevSecOps platform:

- Build environments for iOS and Android development
- Secure code signing and certificate management
- App store distribution for Google Play and Apple App Store

## Build environments

For complete control over the build environment, you can use [GitLab-hosted runners](../runners/_index.md),
or set up [self-managed runners](https://docs.gitlab.com/runner/#use-self-managed-runners).

## Code signing

All Android and iOS apps must be securely signed before being distributed through
the various app stores. Signing ensures that applications haven't been tampered with
before reaching a user's device.

With [project-level secure files](../secure_files/_index.md), you can store the following
in GitLab, so that they can be used to securely sign apps in CI/CD builds:

- Keystores
- Provision profiles
- Signing certificates

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project-level secure files demo](https://youtu.be/O7FbJu3H2YM).

## Distribution

Signed builds can be uploaded to the Google Play Store or Apple App Store by using
the Mobile DevOps Distribution integrations.

## Related topics

For step-by-step guidance on implementing Mobile DevOps, see:

- [Tutorial: Build Android apps with GitLab Mobile DevOps](mobile_devops_tutorial_android.md)
- [Tutorial: Build iOS apps with GitLab Mobile DevOps](mobile_devops_tutorial_ios.md)
