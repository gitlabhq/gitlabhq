---
stage: Mobile
group: Mobile Devops
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Build Android apps with GitLab Mobile DevOps'
---

In this tutorial, you'll create a pipeline by using GitLab CI/CD that builds your Android mobile app,
signs it with your credentials, and distributes it to app stores.

To set up mobile DevOps:

1. [Set up your build environment](#set-up-your-build-environment)
1. [Configure code signing with fastlane and Gradle](#configure-code-signing-with-fastlane-and-gradle)
1. [Set up Android apps distribution with Google Play integration and fastlane](#set-up-android-apps-distribution-with-google-play-integration-and-fastlane)

## Before you begin

Before you start this tutorial, make sure you have:

- A GitLab account with access to CI/CD pipelines
- Your mobile app code in a GitLab repository
- A Google Play developer account
- [`fastlane`](https://fastlane.tools) installed locally

## Set up your build environment

Use [GitLab-hosted runners](../runners/_index.md),
or set up [self-managed runners](https://docs.gitlab.com/runner/#use-self-managed-runners)
for complete control over the build environment.

Android builds use Docker images, offering multiple Android API versions.

1. Create a `.gitlab-ci.yml` file in your repository root.
1. Add a Docker image from [Fabernovel](https://hub.docker.com/r/fabernovel/android/tags):

   ```yaml
   test:
     image: fabernovel/android:api-33-v1.7.0
     stage: test
     script:
       - fastlane test
   ```

## Configure code signing with fastlane and Gradle

To set up code signing for Android:

1. Create a keystore:

   1. Run the following command to generate a keystore file:

      ```shell
      keytool -genkey -v -keystore release-keystore.jks -storepass password -alias release -keypass password \
      -keyalg RSA -keysize 2048 -validity 10000
      ```

   1. Put the keystore configuration in the `release-keystore.properties` file:

      ```plaintext
      storeFile=.secure_files/release-keystore.jks
      keyAlias=release
      keyPassword=password
      storePassword=password
      ```

   1. Upload both files as [Secure Files](../secure_files/_index.md) in your project settings.
   1. Add both files to your `.gitignore` file so they aren't committed to version control.
1. Configure Gradle to use the newly created keystore. In the app's `build.gradle` file:

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

The following are sample `fastlane/Fastfile` and `.gitlab-ci.yml` files with this configuration:

- `fastlane/Fastfile`:

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Create and sign a new build"
    lane :build do
      gradle(tasks: ["clean", "assembleRelease", "bundleRelease"])
    end
  end
  ```

- `.gitlab-ci.yml`:

  ```yaml
  build:
    image: fabernovel/android:api-33-v1.7.0
    stage: build
    script:
      - apt update -y && apt install -y curl
      - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
      - fastlane build
  ```

## Set up Android apps distribution with Google Play integration and fastlane

Signed builds can be uploaded to the Google Play Store by using the Mobile DevOps Distribution integrations.

1. [Create a Google service account](https://docs.fastlane.tools/actions/supply/#setup) in Google Cloud Platform and grant that account access to the project in Google Play.
1. Enable the Google Play integration:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select **Settings > Integrations**.
   1. Select **Google Play**.
   1. Under **Enable integration**, select the **Active** checkbox.
   1. In **Package name**, enter the package name of the app. For example, `com.gitlab.app_name`.
   1. In **Service account key (.JSON)** drag or upload your key file.
   1. Select **Save changes**.
1. Add the release step to your pipeline.

The following is a sample `fastlane/Fastfile`:

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

The following is a sample `.gitlab-ci.yml`:

```yaml
beta:
  image: fabernovel/android:api-33-v1.7.0
  stage: beta
  script:
    - fastlane beta
```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Google Play integration demo](https://youtu.be/Fxaj3hna4uk).

Congratulations! Your app is now set up for automated building, signing, and distribution. Try creating
a merge request to trigger your first pipeline.

## Related topics

See the Mobile DevOps [Android Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/android_demo)
project for a complete build, sign, and release pipeline example for Android.

For additional reference materials, see the [DevOps section](https://about.gitlab.com/blog/categories/devops/) of the GitLab blog.
