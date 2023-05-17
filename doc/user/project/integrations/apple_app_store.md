---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Apple App Store **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104888) in GitLab 15.8 [with a flag](../../../administration/feature_flags.md) named `apple_app_store_integration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/385335) in GitLab 15.10. Feature flag `apple_app_store_integration` removed.

This feature is part of [Mobile DevOps](../../../ci/mobile_devops.md) developed by [GitLab Incubation Engineering](https://about.gitlab.com/handbook/engineering/incubation/).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

With the Apple App Store integration, you can configure your CI/CD pipelines to connect to [App Store Connect](https://appstoreconnect.apple.com) to build and release apps for iOS, iPadOS, macOS, tvOS, and watchOS.

The Apple App Store integration works out of the box with [fastlane](https://fastlane.tools/). You can also use this integration with other build tools.

## Prerequisites

An Apple ID enrolled in the [Apple Developer Program](https://developer.apple.com/programs/enroll/) is required to enable this integration.

## Configure GitLab

GitLab supports enabling the Apple App Store integration at the project level. Complete these steps in GitLab:

1. In the Apple App Store Connect portal, generate a new private key for your project by following [these instructions](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).
1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Apple App Store**.
1. Turn on the **Active** toggle under **Enable Integration**.
1. Provide the Apple App Store Connect configuration information:
   - **Issuer ID**: The Apple App Store Connect issuer ID.
   - **Key ID**: The key ID of the generated private key.
   - **Private Key**: The generated private key. You can download this key only once.

1. Select **Save changes**.

After the Apple App Store integration is activated:

- The global variables `$APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `$APP_STORE_CONNECT_API_KEY_KEY_ID`, `$APP_STORE_CONNECT_API_KEY_KEY`, and `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64` are created for CI/CD use.
- `$APP_STORE_CONNECT_API_KEY_KEY` contains the Base64 encoded Private Key.
- `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64` is always `true`.

## Security considerations

### CI/CD variable security

Malicious code pushed to your `.gitlab-ci.yml` file could compromise your variables, including
`$APP_STORE_CONNECT_API_KEY_KEY`, and send them to a third-party server. For more details, see
[CI/CD variable security](../../../ci/variables/index.md#cicd-variable-security).

## Enable the integration in fastlane

To enable the integration in fastlane and upload a TestFlight or public App Store release, you can add the following code to your app's `fastlane/Fastfile`:

```ruby
app_store_connect_api_key
```
