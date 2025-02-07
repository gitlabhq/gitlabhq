---
stage: none
group: unassigned
info: This is a GitLab Incubation Engineering program. No technical writer assigned to this group.
title: Apple App Store Connect
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104888) in GitLab 15.8 [with a flag](../../../administration/feature_flags.md) named `apple_app_store_integration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/385335) in GitLab 15.10. Feature flag `apple_app_store_integration` removed.

This feature is part of [Mobile DevOps](../../../ci/mobile_devops/_index.md) developed by [GitLab Incubation Engineering](https://handbook.gitlab.com/handbook/engineering/development/incubation/).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

Use the Apple App Store Connect integration to configure your CI/CD pipelines to connect to [App Store Connect](https://appstoreconnect.apple.com).
With this integration, you can build and release apps for iOS, iPadOS, macOS, tvOS, and watchOS.

The Apple App Store Connect integration works out of the box with [fastlane](https://fastlane.tools/). You can also use this integration with other build tools.

## Enable the integration in GitLab

Prerequisites:

- You must have an Apple ID enrolled in the [Apple Developer Program](https://developer.apple.com/programs/enroll/).
- You must [generate a new private key](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api) for your project in the Apple App Store Connect portal.

To enable the Apple App Store Connect integration in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Apple App Store Connect**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Provide the Apple App Store Connect configuration information:
   - **Issuer ID**: The Apple App Store Connect issuer ID.
   - **Key ID**: The key ID of the generated private key.
   - **Private key**: The generated private key. You can download this key only once.
   - **Protected branches and tags only**: Enable to set variables on protected branches and tags only.
1. Select **Save changes**.

After you enable the integration:

- The global variables `$APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `$APP_STORE_CONNECT_API_KEY_KEY_ID`, `$APP_STORE_CONNECT_API_KEY_KEY`, and `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64` are created for CI/CD use.
- `$APP_STORE_CONNECT_API_KEY_KEY` contains the Base64-encoded private key.
- `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64` is always `true`.

## Security considerations

### CI/CD variable security

Malicious code pushed to your `.gitlab-ci.yml` file could compromise your variables, including
`$APP_STORE_CONNECT_API_KEY_KEY`, and send them to a third-party server. For more information, see
[CI/CD variable security](../../../ci/variables/_index.md#cicd-variable-security).

## Enable the integration in fastlane

To enable the integration in fastlane and upload a TestFlight or public App Store release, you can add the following code to your app's `fastlane/Fastfile`:

```ruby
app_store_connect_api_key
```
