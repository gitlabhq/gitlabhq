---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: DevSecOps Workflow - Mobile Apps
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This document provides the instruction and functional detail for GitLab DevSecOps Workflow solution for building and delivering hybrid (React Native) mobile apps.

For native mobile application using fastlane, refer to product documentation.

The instructions include a sample [**React Native**](https://reactnative.dev) application, bootstrapped using `react-native-community/cli`, and provide a cross-platform solution on both iOS and Android devices. The sample project provides an end-to-end solution for using GitLab CI/CD pipelines to build, test and deploy a mobile application.

## Getting Started

Follow the steps below on how to use this React Native Mobile App sample project to jump start your mobile application delivery using GitLab.

### Download the Solution Component

1. Obtain the invitation code from your account team.
1. Download the solution component from [the solution component webstore](https://cloud.gitlab-accelerator-marketplace.com) by using your invitation code.

### Set Up the Solution Component Project

- The Mobile App solution component from the Product Accelerator marketplace has been downloaded. In the solution pack, it includes the mobile app sample project with the CI/CD files.
- Create a new GitLab CI/CD catalog project to host the Snyk component in your environment. In the mobile app solution pack, it includes the Snyk CI/CD component project files which allow you to set up the Snyk CI/CD catalog project.
  1. Create a new GitLab project to host this Snyk CI/CD catalog project
  1. Copy the provided files into your project
  1. Configure the required CI/CD variables in your project settings
  1. Make sure the project is marked as a CI/CD catalog project. For more information, see [publish a component project](../../ci/components/_index.md#publish-a-component-project).
  > There is a public GitLab Snyk component on GitLab.com, if you are on SaaS, and you are able to access the public GitLab Snyk component, to set up your own Snyk CI/CD catalog project is not needed, and you can follow the documentation in the public GitLab Snyk component on GitLab.com to use the component directly.
- Use the Change Control Workflow with ServiceNow solution pack to configure the DevOps Change Velocity integration with GitLab to automate change request creation in ServiceNow for deployments require change controls. [Here](../../solutions/components/integrated_servicenow.md) is the documentation link to the change control workflow with ServiceNow solution component, and work with your account team to get an access code to download the Change Control Workflow with ServiceNow solution package.
- Copy the CI YAML files into your project:
  - `.gitlab-ci.yml`
  - `build-android.yml` in the pipelines directory. You will need to update the file path in `.gitlab-ci.yml` if the `build-android.yml` file is put in a different location other than /pipeline because the main `.gitlab-ci.yml` file references the `build-android.yml` file for the build job.
  - `build-ios.yml` in the pipelines directory. You will need to update the file path in `.gitlab-ci.yml` if the `build-ios.yml` file is put in a different location other than /pipeline because the main `.gitlab-ci.yml` file references the `build-ios.yml` file for the build job.

   ```yaml
   include:
  - local: "pipelines/build-ios.yml"
    inputs:
      image: macos-15-xcode-16
      tag: saas-macos-medium-m1
  - local: "pipelines/build-android.yml"
    inputs:
      image: reactnativecommunity/react-native-android
   ```

- Configure the required CI/CD variables in your project settings. See the following section to learn how the pipeline works.

## How the Pipeline Works

This pipeline is designed for a React Native project, handling both iOS and Android builds, test and deploy the Mobile App.

This project includes a simple reactCounter demo app for React Native build for both iOS and Android. This version does not sign the artifacts yet, so we cannot upload to TestFlight or the Play Store.

Each change uses a component for semantic versioning bumps, which has that version stored as an ephemeral variable used to commit
generic packages to the package registry.

## Pipeline Structure

The pipeline consists of the following stages and jobs:

1. prebuild
   - unit test
   - Snyk scans
1. build
   - build IoS package
   - build Android package
1. test
   - dependency scanning
   - SAST scanning
1. functional-test
   - upload_ios/android_app_to_sauce_labs
   - automated_test_appium_saucelabs
1. app-distribution
   - app_distribution_sauce_android
   - app_distribution_sauce_ios
1. beta-release
   - beta-release-dev
   - beta-release-approval

## Prerequisites

There are multiple third party tools integrated in the mobile pipeline workflow. In order to successfully run the pipeline, make sure the following prerequisites are in place.

### Snyk Integration using the Component

In order to use the GitLab Snyk CI/CD component for security scans, make sure your group or project in GitLab is already connected with Snyk, if not, follow [this tutorial](https://docs.snyk.io/scm-ide-and-ci-cd-integrations/snyk-scm-integrations/gitlab) to configure it.

In the mobile app project, add the required variables for the Snyk integration.

#### Required CI/CD Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `SNYK_TOKEN` | API token to access Snyk | `d7da134c-xxxxxxxxxx` |

This mobile app demo project uses a private Snyk component, that's the reason why we added the following additional variables for the mobile app project to access the private Snyk component project, but this is not needed if your Snyk component is public or accessible within your group.

```yaml
SNYK_PROJECT_ACCESS_USERNAME: "MOBILE_APP_SNYK_COMPONENT_ACCESS"
DOCKER_AUTH_CONFIG: '{"auths":{"registry.gitlab.com":{"username":"$SNYK_PROJECT_ACCESS_USERNAME","password":"$SNYK_PROJECT_ACCESS_TOKEN"}}}'
```

#### Update the component path

Update the component path in the `.gitlab-ci.yml` file so that the pipeline can successfully reference the Snyk component.

```yaml
 - component: $CI_SERVER_FQDN/gitlab-com/product-accelerator/work-streams/packaging/snyk/snyk@1.0.0 #snky sast scan, this examples uses the component in GitLab the product accelerator group. Please update the path and stage accordingly.
    inputs:
      stage: prebuild
      token: $SNYK_TOKEN
```

### Sauce Labs Intergration

This mobile app demo project CI/CD is integrated with Sauce Labs for automated functional testing. In order to run the automated test in Sauce Labs, the application needs to be uploaded into Sauce Labs app storage. You will need to set the required variables for the project in GitLab to access Sauce Labs and upload the artifacts.

#### Required CI/CD Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `SAUCE_USERNAME` | Sauce Labs username| `rz` |
| `SAUCE_ACCESS_KEY` | API key to access Sauce Labs  | `9f5wewwc-xxxxxxx` |
| `APP_FILE_PATH_IOS` | file path to find the build artifacts | `ios/build/reactCounter.ipa` |
| `APP_FILE_PATH_ANDROID` | file path to find the build artifacts | `android/app/build/outputs/apk/release/app-release.apk` |

#### Use Appium for automated testing

In order to use SauceLabs for automated testing, the app has to be uploaded to SauceLab App Management. The pipeline uses the API endpoint to upload the app to SauceLabs and make it available for testing.

Added an Appium test script file in `tests/appium`for testing the React Native mobile application using WebdriverIO and Sauce Labs. The test script will use the following environment variables to access SauceLabs

``` bash
# Using the variables defined in the project

const SAUCE_USERNAME = process.env.SAUCE_USERNAME;
const SAUCE_ACCESS_KEY = process.env.SAUCE_ACCESS_KEY;

```

#### App Distribution (Android and iOS)

GitLab pipeline distributes the app builds to SauceLabs TestFairy for demo purposes. SauceLabs TestFairy allows users to get new versions of the app to testers for review and testing.

### ServiceNow Integration

This mobile app demo project CI/CD is integrated with ServiceNow for change controls. When the pipeline reaches the deployment job that has the change control enabled in ServiceNow, it will automatically create a change request. Once the change request is approved, the deployment job will resume. With this demo project, the beta release approval job is gated in ServiceNow and requires manual approval to proceed.

#### CI/CD Variables

In order for the pipeline to communicate with ServiceNow, the webhook integrations need to be created. If you are using API endpoints to communicates with ServiceNow, you will need to include the following variables. However, this is not required when using the ServiceNow DevOps Change Velocity integration. As part of the ServiceNow DevOps Change Velocity onboarding, the webhooks will be created.

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `SNOW_URL` | URL of your SeriveNow instance| `https://<SNOW_INSTANCE>.com/` |
| `SNOW_TOOLID` | ServiceNow instance ID  | `3b5w345629212105c5ddaccwonworw2` |
| `SNOW_TOKEN` | API token to access ServiceNow| `Oxxxxxxxxxx` |

## Included Files and Components

The mobile app project pipeline includes several external configurations and components:

- Local build configurations for iOS and Android
- SAST (Static Application Security Testing) component
- Auto-semversioning component
- Dependency scanning
- Snyk SAST scan component

## Notes

Reach out to your account team for obtaining an invitation code to access the solution component and for any additional questions.
