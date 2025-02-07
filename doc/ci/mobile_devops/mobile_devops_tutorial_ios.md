---
stage: Mobile
group: Mobile Devops
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Build iOS apps with GitLab Mobile DevOps'
---

In this tutorial, you'll create a pipeline by using GitLab CI/CD that builds your iOS mobile app,
signs it with your credentials, and distributes it to app stores.

To set up mobile DevOps:

1. [Set up your build environment](#set-up-your-build-environment)
1. [Configure code signing with fastlane](#configure-code-signing-with-fastlane)
1. [Set up app distribution with Apple Store integration and fastlane](#set-up-app-distribution-with-apple-store-integration-and-fastlane)

## Before you begin

Before you start this tutorial, make sure you have:

- A GitLab account with access to CI/CD pipelines
- Your mobile app code in a GitLab repository
- An Apple Developer account
- [`fastlane`](https://fastlane.tools) installed locally

## Set up your build environment

Use [GitLab-hosted runners](../runners/_index.md),
or set up [self-managed runners](https://docs.gitlab.com/runner/#use-self-managed-runners)
for complete control over the build environment.

1. Create a `.gitlab-ci.yml` file in your repository root.
1. Add a [supported macOS images](../runners/hosted_runners/macos.md#supported-macos-images) to run a job on a [macOS GitLab hosted runners](../runners/hosted_runners/macos.md) (beta):

   ```yaml
   test:
     image: macos-14-xcode-15
     stage: test
     script:
       - fastlane test
     tags:
       - saas-macos-medium-m1
   ```

## Configure code signing with fastlane

To set up code signing for iOS, upload signed certificates to GitLab by using fastlane:

1. Initialize fastlane:

   ```shell
   fastlane init
   ```

1. Generate a `Matchfile` with the configuration:

   ```shell
   fastlane match init
   ```

1. Generate certificates and profiles in the Apple Developer portal and upload those files to GitLab:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match development
   ```

1. Optional. If you have already created signing certificates and provisioning profiles for your project, use `fastlane match import` to load your existing files into GitLab:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match import
   ```

You are prompted to input the path to your files. After you provide those details, your files are uploaded and visible in your project's CI/CD settings.
If prompted for the `git_url` during the import, it is safe to leave it blank and press <kbd>enter</kbd>.

The following are sample `fastlane/Fastfile` and `.gitlab-ci.yml` files with this configuration:

- `fastlane/Fastfile`:

  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Build and sign the application for development"
    lane :build do
      setup_ci

      match(type: 'development', readonly: is_ci)

      build_app(
        project: "ios demo.xcodeproj",
        scheme: "ios demo",
        configuration: "Debug",
        export_method: "development"
      )
    end
  end
  ```

- `.gitlab-ci.yml`:

  ```yaml
  build_ios:
    image: macos-12-xcode-14
    stage: build
    script:
      - fastlane build
    tags:
      - saas-macos-medium-m1
  ```

## Set up app distribution with Apple Store integration and fastlane

Signed builds can be uploaded to the Apple App Store by using the Mobile DevOps Distribution integrations.

Prerequisites:

- You must have an Apple ID enrolled in the Apple Developer Program.
- You must generate a new private key for your project in the Apple App Store Connect portal.

To create an iOS distribution with the Apple Store integration and fastlane:

1. Generate an API Key for App Store Connect API. In the Apple App Store Connect portal, [generate a new private key for your project](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).
1. Enable the Apple App Store Connect integration:
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
1. Add the release step to your pipeline and fastlane configuration.

The following is a sample `fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and sign the application for distribution, upload to TestFlight"
  lane :beta do
    setup_ci

    match(type: 'appstore', readonly: is_ci)

    app_store_connect_api_key

    increment_build_number(
      build_number: latest_testflight_build_number(initial_build_number: 1) + 1,
      xcodeproj: "ios demo.xcodeproj"
    )

    build_app(
      project: "ios demo.xcodeproj",
      scheme: "ios demo",
      configuration: "Release",
      export_method: "app-store"
    )

    upload_to_testflight
  end
end
```

The following is a sample `.gitlab-ci.yml`:

```yaml
beta_ios:
  image: macos-12-xcode-14
  stage: beta
  script:
    - fastlane beta
```

Congratulations! Your app is now set up for automated building, signing, and distribution. Try creating
a merge request to trigger your first pipeline.

## Related topics

See the sample reference projects below for complete build, sign, and release pipeline examples for various platforms.
A list of all available projects can be found in [the Mobile DevOps Demo Projects group](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/).

- [iOS Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/ios-demo)
- [Flutter Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/flutter-demo)

For additional reference materials, see the [DevOps section](https://about.gitlab.com/blog/categories/devops/) of the GitLab blog.
