---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Mobile DevOps

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

Use GitLab Mobile DevOps to quickly build, sign, and release native and cross-platform mobile apps
for Android and iOS using GitLab CI/CD. Mobile DevOps is an experimental feature developed by
[GitLab Incubation Engineering](https://handbook.gitlab.com/handbook/engineering/development/incubation/).

Mobile DevOps is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

## Build environments

Get started quickly by using [GitLab-hosted runners](../ci/runners/index.md),
or set up [self-managed runners](https://docs.gitlab.com/runner/#use-self-managed-runners)
for complete control over the build environment.

### Android build environments

Set up an Android build environment by selecting an appropriate Docker image
and adding it to your `.gitlab-ci.yml` file. [Fabernovel](https://hub.docker.com/r/fabernovel/android/tags)
provides a variety of supported Android versions.

For example:

```yaml
test:
  image: fabernovel/android:api-33-v1.7.0
  stage: test
  script:
    - fastlane test
```

### iOS build environments

[GitLab hosted runners on macOS](../ci/runners/hosted_runners/macos.md) are in beta.

[Choose an image](../ci/runners/hosted_runners/macos.md#supported-macos-images) to run a job on a macOS GitLab-hosted runner and add it to your `.gitlab-ci.yml` file.

For example:

```yaml
test:
  image: macos-14-xcode-15
  stage: test
  script:
    - fastlane test
  tags:
    - saas-macos-medium-m1
```

## Code signing

All Android and iOS apps must be securely signed before being distributed through
the various app stores. Signing ensures that applications haven't been tampered with
before reaching a user's device.

With [project-level secure files](secure_files/index.md), you can store the following
in GitLab, so that they can be used to securely sign apps in CI/CD builds:

- Keystores
- Provision profiles
- Signing certificates

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Project-level secure files demo](https://youtu.be/O7FbJu3H2YM).

### Code signing Android projects with fastlane & Gradle

To set up code signing for Android:

1. Upload your keystore and keystore properties files to project-level secure files.
1. Update the Gradle configuration to use those files in the build.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [How to build and release an Android app to Google Play with GitLab](https://youtu.be/u8yC8W2k85U).

#### Create a keystore

Run the following command to generate a keystore file if you don't already have one:

```shell
keytool -genkey -v -keystore release-keystore.jks -storepass password -alias release -keypass password -keyalg RSA -keysize 2048 -validity 10000
```

Next, put the keystore configuration in a file called `release-keystore.properties`,
which should look similar to this example:

```plaintext
storeFile=.secure_files/release-keystore.jks
keyAlias=release
keyPassword=password
storePassword=password
```

After these files are created:

- [Upload them as Secure Files](secure_files/index.md) in the GitLab project
  so they can be used in CI/CD jobs.
- Add both files to your `.gitignore` file so they aren't committed to version control.

#### Configure Gradle

The next step is to configure Gradle to use the newly created keystore. In the app's `build.gradle` file:

1. Immediately after the plugins section, add:

   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('.secure_files/release-keystore.properties')
   if (keystorePropertiesFile.exists()) {
     keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   ```

1. Anywhere in the `android` block, add:

   ```gradle
   signingConfigs {
     release {
       keyAlias keystoreProperties['keyAlias']
       keyPassword keystoreProperties['keyPassword']
       storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
       storePassword keystoreProperties['storePassword']
     }
   }
   ```

1. Add the `signingConfig` to the release build type:

   ```gradle
   signingConfig signingConfigs.release
   ```

With this configuration in place, you can use fastlane to build & sign the app
with the files stored in secure files.

For example:

- Sample `fastlane/Fastfile` file:

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Create and sign a new build"
    lane :build do
      gradle(tasks: ["clean", "assembleRelease", "bundleRelease"])
    end
  end
  ```

- Sample `.gitlab-ci.yml` file:

  ```yaml
  build:
    image: fabernovel/android:api-33-v1.7.0
    stage: build
    script:
      - apt update -y && apt install -y curl
      - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
      - fastlane build
  ```

### Code sign iOS projects with fastlane

To set up code signing for iOS, you must:

1. Install fastlane locally so you can upload your signing certificates to GitLab.
1. Configure the build to use those files.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [How to build and release an iOS app to Test Flight with GitLab](https://youtu.be/Ar8IsBgP1as).

#### Initialize fastlane

With fastlane installed, start by running:

```shell
fastlane init
```

This command creates a `fastlane` folder in the project with an `Appfile` and a stubbed-out `fastfile`.
During this process, you are prompted for App Store Connect login credentials to generate an app identifier and an App Store app if they don't already exist.

The next step sets up fastlane match to manage code signing files for the project.
Run the following command to generate a `Matchfile` with the configuration:

```shell
fastlane match init
```

This command prompts you to:

- Choose which storage backend you want to use, you must select `gitlab_secure_files`.
- Input your project path, for example `gitlab-org/gitlab`.

#### Generate and upload certificates

Run the following command to generate certificates and profiles in the Apple Developer portal
and upload those files to GitLab:

```shell
PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match development
```

In this example:

- `YOUR-TOKEN` must be either a personal or project access token with Maintainer role for the GitLab project.
- Replace `development` with the type of build you want to sign, for example `appstore` or `ad-hoc`.

You can view the files in your project's CI/CD settings as soon as the command completes.

#### Upload-only

If you have already created signing certificates and provisioning profiles for your project,
you can optionally use `fastlane match import` to load your existing files into GitLab:

```shell
PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match import
```

You are prompted to input the path to your files. After you provide those details,
your files are uploaded and visible in your project's CI/CD settings.
If prompted for the `git_url` during the import, it is safe to leave it blank and press <kbd>enter</kbd>.

With this configuration in place, you can use fastlane to build and sign the app with
the files stored in secure files.

For example:

- Sample `fastlane/Fastfile` file:

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

- Sample `.gitlab-ci.yml` file:

  ```yaml
  build_ios:
    image: macos-12-xcode-14
    stage: build
    script:
      - fastlane build
    tags:
      - saas-macos-medium-m1
  ```

## Distribution

Signed builds can be uploaded to the Google Play Store or Apple App Store by using
the Mobile DevOps Distribution integrations.

### Android distribution with Google Play integration and fastlane

To create an Android distribution with Google Play integration and fastlane, you must:

1. [Create a Google service account](https://docs.fastlane.tools/actions/supply/#setup)
   in Google Cloud Platform and grant that account access to the project in Google Play.
1. [Enable the Google Play integration](#enable-google-play-integration).
1. Add the release step to your pipeline.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Google Play integration demo](https://youtu.be/Fxaj3hna4uk).

#### Enable Google Play Integration

Use the [Google Play integration](../user/project/integrations/google_play.md),
to configure your CI/CD pipelines to connect to the [Google Play Console](https://play.google.com/console/developers)
to build and release Android apps. To enable the integration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Google Play**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Package name**, enter the package name of the app. For example, `com.gitlab.app_name`.
1. In **Service account key (.JSON)** drag or upload your key file.
1. Select **Save changes**.

With the integration enabled, you can use fastlane to distribute a build to Google Play.

For example:

- Sample `fastlane/Fastfile`:

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Submit a new Beta build to the Google Play store"
    lane :beta do
      upload_to_play_store(
        track: 'internal',
        aab: 'app/build/outputs/bundle/release/app-release.aab',
        release_status: 'draft'
      )
    end
  end
  ```

- Sample `.gitlab-ci.yml`:

  ```yaml
  beta:
    image: fabernovel/android:api-33-v1.7.0
    stage: beta
    script:
      - fastlane beta
  ```

### iOS distribution Apple Store integration and fastlane

To create an iOS distribution with the Apple Store integration and fastlane, you must:

1. Generate an API Key for App Store Connect API. In the Apple App Store Connect portal,
   [generate a new private key for your project](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).
1. [Enable the Apple App Store Connect integration](#enable-the-apple-app-store-connect-integration).
1. Add the release step to your pipeline and fastlane configuration.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Apple App Store Connect integration demo](https://youtu.be/CwzAWVgJeK8).
<!-- Video published on 2023-03-17 -->

#### Enable the Apple App Store Connect integration

Prerequisites:

- You must have an Apple ID enrolled in the [Apple Developer Program](https://developer.apple.com/programs/enroll/).
- You must [generate a new private key](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api) for your project in the Apple App Store Connect portal.

Use the Apple App Store Connect integration to configure your CI/CD pipelines to connect to [App Store Connect](https://appstoreconnect.apple.com).
With this integration, you can build and release apps for iOS, iPadOS, macOS, tvOS, and watchOS.

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

With the integration enabled, you can use fastlane to distribute a build to TestFlight
and the Apple App Store.

For example:

- Sample `fastlane/Fastfile`:

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

- Sample `.gitlab-ci.yml`:

  ```yaml
  beta_ios:
    image: macos-12-xcode-14
    stage: beta
    script:
      - fastlane beta
  ```

## Review apps for mobile

You can use [review apps](review_apps/index.md) to preview changes directly from a merge request.
This feature is possible through an integration with [Appetize.io](https://appetize.io/).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Review apps for mobile setup instructions](https://youtu.be/X15mI19TXa4).

To get started, see the [setup instructions](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/15).

## Sample Reference Projects

See the sample reference projects below for complete build, sign, and release pipeline examples for various platforms. A list of all available projects can be found in [the Mobile DevOps Demo Projects group](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/).

- [Android Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/android_demo)
- [iOS Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/ios-demo)
- [Flutter Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/flutter-demo)

## Mobile DevOps Blog

Additional reference material can be found in the [DevOps section](https://about.gitlab.com/blog/categories/devops/) of the GitLab blog.
