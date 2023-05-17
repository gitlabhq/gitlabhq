---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code signing for SaaS runners on macOS

Before you can integrate GitLab with Apple services, install to a device, or deploy to the Apple App Store, you must [code sign](https://developer.apple.com/support/code-signing/) your application.

## Code signing iOS Projects with fastlane

When you use SaaS runners on macOS, each job runs on a VM. Included in each VM is [fastlane](https://fastlane.tools/),
an open-source solution aimed at simplifying mobile app deployment.

For information about how to set up code signing for your application, see the instructions in the [Mobile DevOps documentation](../../../../ci/mobile_devops.md#code-sign-ios-projects-with-fastlane).

These instructions provide the minimal setup to use fastlane to code sign your application. For more information about using fastlane to handle code signing, see the following resources:

- [fastlane getting started guide](https://docs.fastlane.tools/)
- [Best practices for integrating with GitLab CI](https://docs.fastlane.tools/best-practices/continuous-integration/gitlab/)
- [fastlane code signing getting started guide](https://docs.fastlane.tools/codesigning/getting-started/)

## Related topics

- [Apple Developer Support - Code Signing](https://developer.apple.com/support/code-signing/)
- [Code Signing Best Practice Guide](https://codesigning.guide/)
- [fastlane authentication with Apple Services guide](https://docs.fastlane.tools/getting-started/ios/authentication/)
