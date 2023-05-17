---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Google Play **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111621) in GitLab 15.10 [with a flag](../../../administration/feature_flags.md) named `google_play_integration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/389611) in GitLab 15.11. Feature flag `google_play_integration` removed.

This feature is part of [Mobile DevOps](../../../ci/mobile_devops.md) developed by [GitLab Incubation Engineering](https://about.gitlab.com/handbook/engineering/incubation/).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

With the Google Play integration, you can configure your CI/CD pipelines to connect to the [Google Play Console](https://play.google.com/console) to build and release apps for Android devices.

The Google Play integration works out of the box with [fastlane](https://fastlane.tools/). You can also use this integration with other build tools.

## Enable the integration in GitLab

Prerequisites:

- You must have a [Google Play Console](https://play.google.com/console/developers) developer account.
- You must [generate a new service account key for your project](https://developers.google.com/android-publisher/getting_started) from the Google Cloud console.

To enable the Google Play integration in GitLab:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Google Play**.
1. In **Enable integration**, select the **Active** checkbox.
1. In **Package name**, enter the package name of the app (for example, `com.gitlab.app_name`).
1. In **Service account key (.JSON)**, drag or upload your key file.
1. Select **Save changes**.

After you enable the integration, the global variables `$SUPPLY_PACKAGE_NAME` and `$SUPPLY_JSON_KEY_DATA` are created for CI/CD use.

### CI/CD variable security

Malicious code pushed to your `.gitlab-ci.yml` file could compromise your variables, including `$SUPPLY_JSON_KEY_DATA`, and send them to a third-party server. For more information, see [CI/CD variable security](../../../ci/variables/index.md#cicd-variable-security).

## Enable the integration in fastlane

To enable the integration in fastlane and upload the build to the given track in Google Play, you can add the following code to your app's `fastlane/Fastfile`:

```ruby
upload_to_play_store(
  track: 'internal',
  aab: '../build/app/outputs/bundle/release/app-release.aab'
)
```
