---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Mobile DevOps

GitLab Mobile DevOps is a collection of features and tools designed for mobile developers
and teams to automate their build and release process using GitLab CI/CD. Mobile DevOps
is an experimental feature developed by [GitLab Incubation Engineering](https://about.gitlab.com/handbook/engineering/incubation/).

Mobile DevOps is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

## Code signing

With [project-level secure files](secure_files/index.md), you can manage key stores and provision profiles
and signing certificates directly in a GitLab project.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project-level secure files demo](https://youtu.be/O7FbJu3H2YM).

## Review apps for mobile

You can use [review apps](review_apps/index.md) to preview changes directly from a merge request.
This feature is possible through an integration with [Appetize.io](https://appetize.io/).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Review apps for mobile setup instructions](https://youtu.be/X15mI19TXa4).

To get started, see the [setup instructions](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/15).

## Mobile SAST

You can use [Static Application Security Testing (SAST)](../user/application_security/sast/index.md)
to run static analyzers on code to check for known security vulnerabilities. Mobile SAST
expands this functionality for mobile teams with an [experimental SAST feature](../user/application_security/sast/index.md#experimental-features)
based on [Mobile Security Framework (MobSF)](https://github.com/MobSF/Mobile-Security-Framework-MobSF).

## Automated releases

With the [Apple App Store integration](../user/project/integrations/apple_app_store.md), you can configure your CI/CD pipelines to connect to [App Store Connect](https://appstoreconnect.apple.com/) to build and release apps for iOS, iPadOS, macOS, tvOS, and watchOS.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Apple App Store integration demo](https://youtu.be/CwzAWVgJeK8).

With the [Google Play integration](../user/project/integrations/google_play.md), you can configure your CI/CD pipelines to connect to the [Google Play Console](https://play.google.com/console) to build and release apps for Android devices.
