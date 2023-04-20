---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Apple App Store **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104888) in GitLab 15.8 [with a flag](../../../administration/feature_flags.md) named `apple_app_store_integration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/385335) in GitLab 15.10. Feature flag `apple_app_store_integration` removed.

With the Apple App Store integration, you can configure your CI/CD pipelines to connect to [App Store Connect](https://appstoreconnect.apple.com) to build and release apps for iOS, iPadOS, macOS, tvOS, and watchOS.

The integration is designed to be able to work out of the box with [fastlane](http://fastlane.tools/), but can be used with other build tools as well.

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
   - **Issuer ID**: The Apple App Store Connect Issuer ID can be found in the *Keys* section under *Users and Access* the Apple App Store Connect portal.
   - **Key ID**: The Key ID of the new private key that was just generated.
   - **Private Key**: The Private Key that was just generated. Note: you are only be able to download this key one time.

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

## fastlane Example

Because this integration works out of the box with fastlane adding the code below to an app's `fastlane/Fastfile` activates the integration, and create the connection for any interactions with the Apple App Store uploading a Test Flight or public App Store release.

```ruby
app_store_connect_api_key
```
