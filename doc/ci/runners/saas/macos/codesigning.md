---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code signing for SaaS runners on macOS

Before you can integrate GitLab with Apple services, install to a device, or deploy to the Apple App Store, you must [code sign](https://developer.apple.com/support/code-signing/) your application.

To code sign an iOS project, you need the following files:

- A certificate issued by Apple.
- A provisioning profile.

## Code signing iOS Projects with fastlane

When you use SaaS runners on macOS, each job runs on a VM. Included in each VM is [fastlane](https://fastlane.tools/),
an open-source solution aimed at simplifying mobile app deployment.

These steps outline the minimal setup required to use fastlane to code sign your application. Refer to the fastlane [getting started guide](https://docs.fastlane.tools/), [best practices for integrating with GitLab CI](https://docs.fastlane.tools/best-practices/continuous-integration/gitlab/) and the [fastlane code signing getting started guide](https://docs.fastlane.tools/codesigning/getting-started/) for installation instructions, and an overview of how to use fastlane to handle code signing.

To use fastlane to code sign your application:

1. At the root of your project repository, on your local development system, run this command:

   ```plaintext
   fastlane match init
   ```

   This command creates the `fastlane` directory and adds two files: `Fastfile` and `Appfile`.

1. Open `Appfile` and edit it to include your Apple ID and app ID.

   ```plaintext
   app_identifier("APP IDENTIFIER") # The bundle identifier of your app

   apple_id("APPLE ID") # Your Apple email address
   ```

1. Open `Fastfile`, which includes the fastlane build steps.
   In the following snippet, the steps `get_certificates`, `get_provisioning_profile,match`, `gym`, and
   `upload_to_testflight` are fastlane [actions](https://docs.fastlane.tools/actions/).

   ```plaintext
   # This file contains the fastlane.tools configuration
   # You can find the documentation at https://docs.fastlane.tools

   default_platform(:ios)

   platform :ios do
     desc "Build the application"
     lane :beta do
       increment_build_number(
       build_number: latest_testflight_build_number + 1,
       xcodeproj: "${PROJECT_NAME}.xcodeproj"
     )
       get_certificates
       get_provisioning_profile
       # match(type: "appstore",read_only: true)
       gym
       upload_to_testflight
     end
   end
   ```

The example configuration also includes an optional `Gymfile`. This file stores configuration
parameters and is used by the fastlane [`gym`](https://docs.fastlane.tools/actions/gym/) action.

## Using fastlane match

To simplify the code signing process and implement the
[Code Signing Best Practices Guide](https://codesigning.guide/) recommendations,
use [fastlane match](https://docs.fastlane.tools/actions/match/).

- Use one code signing identity shared across your team.
- Store the required certificates and provisioning profiles in a separate GitLab project repository.

Match automatically syncs iOS and macOS keys and provisioning profiles across all team members with access to the GitLab project. Each team member with access to the project can use the credentials for code signing.

To use fastlane match:

1. Initialize match in the project repository:

   ```shell
   bundle exec fastlane match init
   ```

1. Select `git` as your storage node.
1. Enter the URL of the GitLab project you plan to use to store your code signing identities.
1. Optional. To create a new certificate and provisioning profile, run:

   ```shell
   bundle exec fastlane match development
   ```

For different code signing identities' storage options, and for a complete step-by-step guide for using match,
refer to the [match documentation](https://docs.fastlane.tools/actions/match/#usage).

### Environment variables and authentication

To complete the setup, you must configure environment variables to use with fastlane. The required variables are outlined in the [fastlane documentation](https://docs.fastlane.tools/best-practices/continuous-integration/#environment-variables-to-set).

To support Apple's two factor authentication requirement, configure these variables:

- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` and
- `FASTLANE_SESSION`

To authenticate fastlane with the App Store for the TestFlight upload, configure these variables:

- `FASTLANE_USER` and
- `FASTLANE_PASSWORD`

View the [fastlane authentication with Apple Services guide](https://docs.fastlane.tools/getting-started/ios/authentication/) for an overview of authentication options.

## Related topics

- [Apple Developer Support - Code Signing](https://developer.apple.com/support/code-signing/)
- [Code Signing Best Practice Guide](https://codesigning.guide/)
