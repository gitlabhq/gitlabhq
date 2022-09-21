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

## Code Signing

[Project-level Secure Files](secure_files/index.md) makes it easier to manage key stores, provision profiles,
and signing certificates directly in a GitLab project.

For a guided walkthrough of this feature, watch the [video demo](https://youtu.be/O7FbJu3H2YM).

## Review Apps for Mobile

You can use [Review Apps](review_apps/index.md) to preview changes directly from a merge request.
Review Apps for Mobile brings that capability to mobile developers through an integration
with [Appetize](https://appetize.io/).

Watch a [video walkthrough](https://youtu.be/X15mI19TXa4) of this feature, or visit the
[setup instructions](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/15)
to get started.

## Mobile SAST

You can use [Static Application Security Testing (SAST)](../user/application_security/sast/index.md)
to run static analyzers on code to check for known security vulnerabilities. Mobile SAST
expands this functionality for mobile teams with an [experimental SAST feature](../user/application_security/sast/index.md#experimental-features)
based on [Mobile Security Framework (MobSF)](https://github.com/MobSF/Mobile-Security-Framework-MobSF).
