---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# VM instances and images for Build Cloud for macOS 

When you use the Build Cloud for macOS:

- Each of your jobs runs in a newly provisioned VM, which is dedicated to the specific job. 
- The VM is active only for the duration of the job and immediately deleted. 

## VM types

The virtual machine where your job runs has `sudo` access with no password.
For the Beta, there is only one available machine type, `gbc-macos-large`.

| Instance type | vCPUS | Memory (GB) |
| --------- | --- | ------- |
|  `gbc-macos-large` | 4 | 10 |

## VM images

You can execute your build on one of the following images.
You specify this image in your `.gitlab-ci.yml` file.

Each image is running a specific version of macOS and Xcode.

| VM image                  | Included software  |
|---------------------------|--------------------|
| macos-10.13-xcode-7       | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| macos-10.13-xcode-8       | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| macos-10.13-xcode-9       | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| macos-10.14-xcode-10      | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/mojave.yml>       |
| macos-10.15-xcode-11      | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/catalina.yml>     |
| macos-11-xcode-12         | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/big-sur.yml>      |

### Image update policy

- Support for new macOS versions is planned.
- Additional details on the support policy and image update release process are documented
  [in this project](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/55bf59c8fa88712960afff2bf6ecc5daa879a8f5/docs/overview.md#os-images).
